//
// ButtonView.m
// Remote
//
// Created by Jason Cardwell on 5/24/11.
// Copyright 2011 Moondeer Studios. All rights reserved.
//
#import "RemoteElementView_Private.h"
#import "ImageView.h"
#import "TitleAttributes.h"
#import "Button.h"
#import "Command.h"
#import "ControlStateTitleSet.h"

// #define DEBUG_BV_COLOR_BG

#define MIN_HIGHLIGHT_INTERVAL 1.0
#define CORNER_RADII           CGSizeMake(5.0f, 5.0f)

static int       ddLogLevel   = LOG_LEVEL_DEBUG;
static const int msLogContext = (LOG_CONTEXT_REMOTE | LOG_CONTEXT_FILE | LOG_CONTEXT_CONSOLE);
#pragma unused(ddLogLevel, msLogContext)


@implementation ButtonView


////////////////////////////////////////////////////////////////////////////////
#pragma mark Internal subviews and constraints
////////////////////////////////////////////////////////////////////////////////


- (void)addInternalSubviews {
  [super addInternalSubviews];

  self.subelementInteractionEnabled = NO;
  self.contentInteractionEnabled    = NO;

  UILabel * labelView = [UILabel newForAutolayout];
  [self addViewToContent:labelView];
  self.labelView = labelView;

  UIActivityIndicatorView * activityIndicator = [UIActivityIndicatorView newForAutolayout];
  activityIndicator.activityIndicatorViewStyle = UIActivityIndicatorViewStyleWhiteLarge;
  activityIndicator.color                      = defaultTitleHighlightColor();
  [self addViewToOverlay:activityIndicator];
  self.activityIndicator = activityIndicator;
}

- (void)updateConstraints {
  [super updateConstraints];

  NSString * labelNametag    = ClassNametagWithSuffix(@"InternalLabel");
  NSString * activityNametag = ClassNametagWithSuffix(@"InternalActivity");

  if (![self constraintsWithNametagPrefix:labelNametag]) {
    UIEdgeInsets titleInsets = self.model.titleEdgeInsets;
    NSString   * constraints =
      $(@"'%1$@' label.left = self.left + %3$f @900\n"
        "'%1$@' label.top = self.top + %4$f @900\n"
        "'%1$@' label.bottom = self.bottom - %5$f @900\n"
        "'%1$@' label.right = self.right - %6$f @900\n"
        "'%2$@' activity.centerX = self.centerX\n"
        "'%2$@' activity.centerY = self.centerY",
        labelNametag, activityNametag, titleInsets.left, titleInsets.top, titleInsets.bottom, titleInsets.right);

    NSDictionary * views = @{@"self": self, @"label": self.labelView, @"activity": self.activityIndicator};

    [self addConstraints:[NSLayoutConstraint constraintsByParsingString:constraints views:views]];
  }
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark Gestures
////////////////////////////////////////////////////////////////////////////////


- (void)attachGestureRecognizers {
  [super attachGestureRecognizers];

  MSLongPressGestureRecognizer * longPressGesture =
    [MSLongPressGestureRecognizer gestureWithTarget:self action:@selector(handleLongPress:)];

  longPressGesture.delaysTouchesBegan = NO;
  longPressGesture.delegate           = self;
  [self addGestureRecognizer:longPressGesture];
  self.longPressGesture = longPressGesture;

  UITapGestureRecognizer * tapGesture =
    [UITapGestureRecognizer gestureWithTarget:self action:@selector(handleTap:)];

  tapGesture.numberOfTapsRequired    = 1;
  tapGesture.numberOfTouchesRequired = 1;
  tapGesture.delaysTouchesBegan      = NO;
  tapGesture.delegate                = self;
  [self addGestureRecognizer:tapGesture];
  self.tapGesture = tapGesture;
}

/// Single tap action executes the primary button command
- (void)handleTap:(UITapGestureRecognizer *)gestureRecognizer {
  if (gestureRecognizer.state == UIGestureRecognizerStateRecognized) {
    self.highlighted = YES;
    assert(self.model.highlighted);

    MSDelayedRunOnMain(_options.minHighlightInterval,
                       ^{
      _flags.highlightActionQueued = NO;
      self.highlighted = NO;
      [self setNeedsDisplay];
    });

    REActionHandler handler = _actionHandlers[@(RESingleTapAction)];

    if (handler)
      handler();

    else
      [self buttonActionWithOptions:CommandOptionDefault];
  } else if (gestureRecognizer.state == UIGestureRecognizerStateCancelled && !_flags.longPressActive) {
//        self.highlighted = NO;
//        [self setNeedsDisplay];
  }
}

/// Long press action executes the secondary button command
- (void)handleLongPress:(MSLongPressGestureRecognizer *)gestureRecognizer {
  if (gestureRecognizer.state == UIGestureRecognizerStateBegan) {
    REActionHandler handler = _actionHandlers[@(RELongPressAction)];

    if (handler)
      handler();

    else
      [self buttonActionWithOptions:CommandOptionLongPress];
  } else if (gestureRecognizer.state == UIGestureRecognizerStatePossible) {
    _flags.longPressActive = YES;
    self.highlighted       = YES;
    [self setNeedsDisplay];
  }
}

/// Enables or disables tap and long press gestures
- (void)updateGesturesEnabled:(BOOL)enabled {
  self.tapGesture.enabled       = enabled;
  self.longPressGesture.enabled = enabled;
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark ￼Button state
////////////////////////////////////////////////////////////////////////////////


- (void)updateState {
  UIControlState currentState = self.state;

  self.userInteractionEnabled = ((currentState & UIControlStateDisabled) ? NO : YES);

  BOOL invalidate = NO;

  NSAttributedString * title = self.model.title;

  if (![self.labelView.attributedText isEqualToAttributedString:title]) {
    self.labelView.attributedText = title;
    invalidate = YES;
  }

  UIImage * icon = self.model.icon.colorImage;

  if (self.icon != icon) {
    self.icon = icon;
    invalidate = YES;
  }

  self.backgroundColor = self.model.backgroundColor;

  if (invalidate) {
    [self invalidateIntrinsicContentSize];
    [self setNeedsDisplay];
  }

}

- (UIControlState)state { return (UIControlState)self.model.state; }


////////////////////////////////////////////////////////////////////////////////
#pragma mark Button actions
////////////////////////////////////////////////////////////////////////////////


- (void)setActionHandler:(REActionHandler)handler forAction:(REAction)action {
  _actionHandlers[@(action)] = handler;
}

- (void)buttonActionWithOptions:(CommandOptions)options {
  assert(self.model);

  if (!self.editing && _flags.commandsActive) {
    if (_flags.longPressActive) {
      _flags.longPressActive = NO;
      [self setNeedsDisplay];
    }

    if (self.model.command.indicator) [_activityIndicator startAnimating];

    CommandCompletionHandler completion =
      ^(BOOL success, NSError * error)
    {
      if ([_activityIndicator isAnimating])
        MSRunAsyncOnMain(^{ [_activityIndicator stopAnimating]; });
    };

    [self.model executeCommandWithOptions:options completion:completion];
  }
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark Content size
////////////////////////////////////////////////////////////////////////////////


- (CGSize)intrinsicContentSize { return self.minimumSize; }

- (CGSize)minimumSize {
  CGRect frame = (CGRect) {
    .size = REMinimumSize
  };

  NSMutableSet * titles = [NSMutableSet set];

  for (NSString *mode in self.model.modes) {
    ControlStateTitleSet * titleSet = [self.model titlesForMode:mode];
    if (titleSet) [titles addObjectsFromArray:[titleSet allValues]];
  }

  if ([titles count]) {

    CGFloat maxWidth = 0.0, maxHeight = 0.0;

    for (NSAttributedString * title in titles) {

      CGSize titleSize = [title size];
      UIEdgeInsets titleInsets = self.titleEdgeInsets;

      titleSize.width  += titleInsets.left + titleInsets.right;
      titleSize.height += titleInsets.top + titleInsets.bottom;

      maxWidth = MAX(titleSize.width, maxWidth);
      maxHeight = MAX(titleSize.height, maxHeight);

    }

    frame.size.width = MAX(maxWidth, frame.size.width);
    frame.size.height = MAX(maxHeight, frame.size.height);
  }


/*
   NSAttributedString * title = self.model.title;

  if (title) {
    CGSize       titleSize   = [title size];
    UIEdgeInsets titleInsets = self.titleEdgeInsets;

    titleSize.width  += titleInsets.left + titleInsets.right;
    titleSize.height += titleInsets.top + titleInsets.bottom;
    frame             = CGRectUnion(frame, (CGRect) {.size = titleSize });
  }

  if (self.icon) {
    CGSize       iconSize    = [self.icon size];
    UIEdgeInsets imageInsets = self.imageEdgeInsets;

    iconSize.width  += imageInsets.left + imageInsets.right;
    iconSize.height += imageInsets.top + imageInsets.bottom;
    frame            = CGRectUnion(frame, (CGRect) {.size = iconSize });
  }

  UIEdgeInsets contentInsets = self.contentEdgeInsets;

  frame.size.width  += contentInsets.left + contentInsets.right;
  frame.size.height += contentInsets.top + contentInsets.bottom;

*/

  if (self.model.proportionLock && !CGSizeEqualToSize(self.bounds.size, CGSizeZero)) {

    CGSize currentSize = self.bounds.size;

    if (currentSize.width > currentSize.height)
      frame.size.height = (frame.size.width * currentSize.height) / currentSize.width;

    else
      frame.size.width = (frame.size.height * currentSize.width) / currentSize.height;
  }

  return frame.size;
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark Subelement views
////////////////////////////////////////////////////////////////////////////////


- (void)addSubelementView:(RemoteElementView *)view {}

- (void)removeSubelementView:(RemoteElementView *)view {}

- (void)addSubelementViews:(NSSet *)views {}

- (void)removeSubelementViews:(NSSet *)views {}

- (NSArray *)subelementViews { return nil; }


////////////////////////////////////////////////////////////////////////////////
#pragma mark Initialization
////////////////////////////////////////////////////////////////////////////////


- (void)initializeIVARs {
  _actionHandlers               = [@{} mutableCopy];
  self.cornerRadii              = CORNER_RADII;
  _options.minHighlightInterval = MIN_HIGHLIGHT_INTERVAL;
  _flags.commandsActive         = YES;

  [super initializeIVARs];
}

- (void)initializeViewFromModel {
  [super initializeViewFromModel];

  _longPressGesture.enabled = (self.model.longPressCommand != nil);

  [self updateState];
  [self invalidateIntrinsicContentSize];
  [self setNeedsDisplay];
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark Key-value observing
////////////////////////////////////////////////////////////////////////////////


- (MSDictionary *)kvoRegistration {

  MSDictionary * reg = [super kvoRegistration];

    reg[@"selected"] = ^(MSKVOReceptionist * receptionist) {
      [(__bridge ButtonView *)receptionist.context updateState];
    };

    reg[@"enabled"] = ^(MSKVOReceptionist * receptionist) {
      ButtonView * buttonView = (__bridge ButtonView *)receptionist.context;
      buttonView.enabled = [receptionist.change[NSKeyValueChangeNewKey] boolValue];
    };

    reg[@"highlighted"] = ^(MSKVOReceptionist * receptionist) {
      [(__bridge ButtonView *)receptionist.context updateState];
    };

    reg[@"style"] = ^(MSKVOReceptionist * receptionist) {
      [(__bridge ButtonView *)receptionist.context setNeedsDisplay];
    };

    reg[@"title"] = ^(MSKVOReceptionist * receptionist) {
      ButtonView         * buttonView = (__bridge ButtonView *)receptionist.context;
      NSAttributedString * title      = NilSafe(receptionist.change[NSKeyValueChangeNewKey]);
      buttonView.labelView.attributedText = title;
    };

    reg[@"image"] = ^(MSKVOReceptionist * receptionist) {
      [(__bridge ButtonView *)receptionist.context updateState];
    };

    reg[@"icon"] = ^(MSKVOReceptionist * receptionist) {
      ButtonView * buttonView = (__bridge ButtonView *)receptionist.context;
      ImageView  * icon       = NilSafe(receptionist.change[NSKeyValueChangeNewKey]);
      buttonView.icon = icon.colorImage;
      [buttonView setNeedsDisplay];
    };

  return reg;
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark Editing
////////////////////////////////////////////////////////////////////////////////


- (void)setEditingMode:(REEditingMode)editingMode {
  [super setEditingMode:editingMode];
  _flags.commandsActive = (editingMode == REEditingModeNotEditing) ? YES : NO;
  [self updateGesturesEnabled:_flags.commandsActive];
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark Drawing
////////////////////////////////////////////////////////////////////////////////


- (void)drawContentInContext:(CGContextRef)ctx inRect:(CGRect)rect {
  if (self.icon) {
    UIGraphicsPushContext(ctx);
    CGRect insetRect = UIEdgeInsetsInsetRect(self.bounds, self.imageEdgeInsets);
    CGSize imageSize = (CGSizeContainsSize(insetRect.size, self.icon.size)
                        ? self.icon.size
                        : CGSizeAspectMappedToSize(self.icon.size, insetRect.size, YES));
    CGRect imageRect = CGRectMake(CGRectGetMidX(insetRect) - imageSize.width / 2.0,
                                  CGRectGetMidY(insetRect) - imageSize.height / 2.0,
                                  imageSize.width,
                                  imageSize.height);

    if (_options.antialiasIcon) {
      CGContextSetAllowsAntialiasing(ctx, YES);
      CGContextSetShouldAntialias(ctx, YES);
    }

    [self.icon drawInRect:imageRect];
    UIGraphicsPopContext();
  }
}

@end
