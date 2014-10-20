//
// RemoteViewController.m
// Remote
//
// Created by Jason Cardwell on 5/3/11.
// Copyright 2011 Moondeer Studios. All rights reserved.
//

#import "RemoteViewController.h"
#import "RemoteElementView.h"
#import "RemoteController.h"
#import "SettingsManager.h"
#import "ButtonGroup.h"
#import "Remote.h"
#import "CoreDataManager.h"
#import "StoryboardProxy.h"
#import "MSRemoteAppController.h"

//#define DUMP_ELEMENT_HIERARCHY
//#define DUMP_LAYOUT_DATA

static int       ddLogLevel   = LOG_LEVEL_DEBUG;
static const int msLogContext = (LOG_CONTEXT_CONSOLE);

@interface RemoteViewController ()
@property (nonatomic, weak,  readwrite) RemoteController   * remoteController;
@property (nonatomic, weak,  readwrite) RemoteView         * remoteView;
@property (nonatomic, weak,  readwrite) NSLayoutConstraint * topToolbarConstraint;
@property (nonatomic, weak,  readwrite) ButtonGroupView    * topToolbarView;

@property (nonatomic, strong) MSNotificationReceptionist * settingsReceptionist;
@property (nonatomic, strong) MSKVOReceptionist          * remoteReceptionist;
@end

@implementation RemoteViewController {
  struct {
    BOOL           addRemoteViewConstraints;
    BOOL           monitorProximitySensor;
    BOOL           autohideTopBar;
    BOOL           remoteInactive;
    BOOL           loadHomeScreen;
    BOOL           monitoringInactivity;
  } _flags;
}

+ (instancetype)viewControllerWithModel:(RemoteController *)model {
  RemoteViewController * controller = nil;
  if (model) {

    controller = [self new];
    controller.remoteController = model;

    controller.remoteReceptionist =
    [MSKVOReceptionist receptionistForObject:model
                                     keyPath:@"currentRemote"
                                     options:NSKeyValueObservingOptionNew
                                     context:NULL
                                       queue:MainQueue
                                     handler:^(MSKVOReceptionist *receptionist,
                                               NSString *keyPath,
                                               id object,
                                               NSDictionary *change,
                                               void *context)
     {
       Remote * remote = (Remote *)change[NSKeyValueChangeNewKey];
       assert(remote && [remote isKindOfClass:[Remote class]]);
       RemoteView * remoteView = [RemoteView viewWithModel:remote];
       [controller insertRemoteView:remoteView];
     }];

    controller.settingsReceptionist =
    [MSNotificationReceptionist receptionistForObject:[SettingsManager class]
                                     notificationName:MSSettingsManagerProximitySensorSettingDidChangeNotification
                                                queue:MainQueue
                                              handler:^(MSNotificationReceptionist *rec,
                                                        NSNotification *note)
    {
      controller->_flags.monitorProximitySensor =
        [SettingsManager boolForSetting:MSSettingsProximitySensorKey];

      CurrentDevice.proximityMonitoringEnabled = controller->_flags.monitorProximitySensor;
    }];
  }
  return controller;
}

/////////////////////////////////////////////////////////////////////////////////
#pragma mark - UIViewController overrides
/////////////////////////////////////////////////////////////////////////////////

/**
 * Releases the cached remote view and any other retained properties relating to the view.
 */
- (void)didReceiveMemoryWarning {
  [super didReceiveMemoryWarning];
}

- (void)viewDidLoad {
  [super viewDidLoad];
  if (!self.remoteController) return;


  [self.view addGestureRecognizer:[UIPinchGestureRecognizer gestureWithTarget:self
                                                                       action:@selector(toggleTopToolbarAction:)]];

  _flags.monitorProximitySensor = [SettingsManager boolForSetting:MSSettingsProximitySensorKey];
  _flags.loadHomeScreen         = YES;

  [self initializeTopToolbar];

  [self insertRemoteView:[RemoteView viewWithModel:self.remoteController.currentRemote]];

}

- (void)updateViewConstraints {

  [super updateViewConstraints];

  if (self.remoteView && _flags.addRemoteViewConstraints) {
    NSString * rawConstraints = (@"remote.centerX = view.centerX\n"
                                 "remote.bottom = view.bottom\n"
                                 "remote.top = view.top");
    NSDictionary * bindings = @{@"view": self.view,
                                @"remote": self.remoteView,
                                @"toolbar": self.topToolbarView};
    NSArray * constraints = [NSLayoutConstraint constraintsByParsingString:rawConstraints views:bindings];
    [self.view addConstraints:constraints];
    _flags.addRemoteViewConstraints = NO;
  }

}

- (void)insertRemoteView:(RemoteView *)remoteView {
  assert(OnMainThread && remoteView);

  _flags.addRemoteViewConstraints = YES;

  if (self.remoteView) {
    [UIView animateWithDuration:0.25
                     animations:^{
                       assert(IsMainQueue);
                       [self.remoteView removeFromSuperview];
                       [self.view insertSubview:remoteView belowSubview:self.topToolbarView];
                       self.remoteView = remoteView;
                       [self.remoteView setNeedsDisplay];
                       [self.view setNeedsUpdateConstraints];
                     }];
  } else {
    [self.view insertSubview:remoteView belowSubview:self.topToolbarView];
    self.remoteView = remoteView;
    [self.remoteView setNeedsDisplay];
    [self.view setNeedsUpdateConstraints];
  }

  #ifdef DUMP_LAYOUT_DATA

    [[NSOperationQueue new] addOperationWithBlock:^{
    int64_t delayInSeconds = 2.0;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void) {
      MSLogDebugInContextTag((LOG_CONTEXT_REMOTE | LOG_CONTEXT_FILE),
                             @"%@ dumping constraints...\n\n%@\n\n",
                             ClassTagSelectorString,
                             [[UIWindow keyWindow]
                              viewTreeDescriptionWithProperties:@[@"frame",
                                                                  @"hasAmbiguousLayout?",
                                                                  @"key",
                                                                  @"nametag",
                                                                  @"name",
                                                                  @"constraints"]]);
    });
  }];
  #endif

  #ifdef DUMP_ELEMENT_HIERARCHY

    [[NSOperationQueue new] addOperationWithBlock:^{
    int64_t delayInSeconds = 4.0;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void) {
      MSLogDebug(@"%@ dumping elements...\n\n%@\n\n",
                 ClassTagSelectorString,
                 [[(RemoteView *)[self.view viewWithNametag:kRemoteViewNametag] model]
                  dumpElementHierarchy]);
    });
  }];

  #endif

// #define LOG_ELEMENTS
  #ifdef LOG_ELEMENTS

    [[NSOperationQueue new] addOperationWithBlock:^{
    int64_t delayInSeconds = 6.0;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void) {

      MSLogDebugInContextTag((LOG_CONTEXT_REMOTE | LOG_CONTEXT_FILE),
                             @"%@\n%@\n%@\n\n%@\n%@\n%@\n",
                             [@"Displayed Remote Element Descriptions" singleBarMessageBox],
                             [_topToolbar.model recursiveDeepDescription],
                             [remoteView.model recursiveDeepDescription],
                             [@"Displayed Remote Element JSON" singleBarMessageBox],
                             [_topToolbar.model JSONString],
                             [remoteView.model JSONString]);

    });
  }];

  #endif
}

- (void)viewDidAppear:(BOOL)animated {
  [super viewDidAppear:animated];

  if (self.remoteController.currentRemote.topBarHidden == (_topToolbarConstraint.constant == 0))
    [self toggleTopToolbar:YES];

}

/**
 * Re-enables proximity monitoring and determines whether toolbar should be visible.
 * @param animated Whether the view is appearing via animation.
 */
- (void)viewWillAppear:(BOOL)animated {
  if (_flags.monitorProximitySensor) CurrentDevice.proximityMonitoringEnabled = YES;

}

/**
 * Ceases proximity monitoring if it had been enabled.
 * @param animated Whether the view is disappearing via animation.
 */
- (void)viewWillDisappear:(BOOL)animated {
  if (_flags.monitorProximitySensor) CurrentDevice.proximityMonitoringEnabled = NO;
}


/////////////////////////////////////////////////////////////////////////////////
#pragma mark - Managing the top toolbar
/////////////////////////////////////////////////////////////////////////////////

- (void)animateToolbar:(CGFloat)constraintConstant {
  [UIView animateWithDuration:0.25
                        delay:0.0
                      options:UIViewAnimationOptionBeginFromCurrentState
                   animations:^{
                     _topToolbarConstraint.constant = constraintConstant;
                     [self.view layoutIfNeeded];
                   }

                   completion:nil];
}

- (void)showTopToolbar:(BOOL)animated {
  CGFloat constant = 0;
  if (animated) [self animateToolbar:constant];
  else _topToolbarConstraint.constant = constant;
}

- (void)hideTopToolbar:(BOOL)animated {
  CGFloat constant = -self.topToolbarView.bounds.size.height;
  if (animated) [self animateToolbar:constant];
  else _topToolbarConstraint.constant = constant;
}

- (void)toggleTopToolbar:(BOOL)animated {
  CGFloat constant = (_topToolbarConstraint.constant ? 0 : -self.topToolbarView.bounds.size.height);
  if (animated) [self animateToolbar:constant];
  else _topToolbarConstraint.constant = constant;
}

/**
 * Creates and attaches the default toolbar items to the items created by the storyboard. Currently
 * this includes a connection status button and a battery status button.
 */
- (void)initializeTopToolbar {
  assert(self.remoteController);

  ButtonGroup * topToolbar = self.remoteController.topToolbar;
  assert(topToolbar);

  ButtonGroupView * topToolbarView = [ButtonGroupView viewWithModel:topToolbar];
  assert(topToolbarView);

  [self.view addSubview:topToolbarView];
  self.topToolbarView = topToolbarView;
  NSLayoutConstraint * topToolbarConstraint = [NSLayoutConstraint constraintWithItem:topToolbarView
                                                                           attribute:NSLayoutAttributeTop
                                                                           relatedBy:NSLayoutRelationEqual
                                                                              toItem:self.view
                                                                           attribute:NSLayoutAttributeTop
                                                                          multiplier:1.0
                                                                            constant:0.0];

  [self.view addConstraint:topToolbarConstraint];
  self.topToolbarConstraint = topToolbarConstraint;

  [self.view addConstraints:[NSLayoutConstraint constraintsByParsingString:@"H:|[view]|"
                                                                     views:@{ @"view" : self.topToolbarView }]];
}

@end
