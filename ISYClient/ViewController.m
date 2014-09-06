//
//  ViewController.m
//  ISYClient
//
//  Created by Jason Cardwell on 9/5/14.
//  Copyright (c) 2014 Moondeer Studios. All rights reserved.
//

#import "ViewController.h"
#import <netdb.h>
#import "MSKit/MSKit.h"

static int ddLogLevel   = LOG_LEVEL_DEBUG;
static int msLogContext = LOG_CONTEXT_CONSOLE;
#pragma unused(ddLogLevel,msLogContext)

static NSString const * kBaseURL = nil; //@"http://192.168.1.9";

@interface ViewController () <NSURLConnectionDelegate, NSURLConnectionDataDelegate, UITextFieldDelegate>

@property (weak, nonatomic) IBOutlet UILabel     * headerLabel;
@property (weak, nonatomic) IBOutlet UILabel     * addressLabel;
@property (weak, nonatomic) IBOutlet UILabel     * addressValue;
@property (weak, nonatomic) IBOutlet UILabel     * portLabel;
@property (weak, nonatomic) IBOutlet UILabel     * portValue;
@property (weak, nonatomic) IBOutlet UILabel     * messagesLabel;
@property (weak, nonatomic) IBOutlet UITextView  * messages;
@property (weak, nonatomic) IBOutlet UILabel     * sendRequestLabel;
@property (weak, nonatomic) IBOutlet UITextField * sendRequest;

@property (strong, nonatomic) dispatch_source_t   groupSource;
@property (strong, nonatomic) NSURLConnection   * deviceConnection;

@property (copy) NSString * location;
@property (copy) NSURL * baseURL;

@end

@implementation ViewController

@synthesize baseURL = _baseURL;

/// viewDidLoad
- (void)viewDidLoad {
  [super viewDidLoad];

  // Visual stuff

  UIFont * headerFont = [UIFont fontWithName:@"User-BoldCameo"   size:24.0];
  UIFont * labelFont  = [UIFont fontWithName:@"User-BoldCameo" size:15.0];
  UIFont * valueFont  = [UIFont fontWithName:@"User-Medium"       size:15.0];

  self.headerLabel.font = headerFont;

  self.addressLabel.font     = labelFont;
  self.portLabel.font        = labelFont;
  self.messagesLabel.font    = labelFont;
  self.sendRequestLabel.font = labelFont;
  self.addressValue.font     = valueFont;
  self.portValue.font        = valueFont;
  self.messages.font         = valueFont;
  self.sendRequest.font      = valueFont;


  // Connection stuff


  if (StringIsEmpty((NSString *)kBaseURL)) {

    self.addressValue.text = @"239.255.255.250";
    self.portValue.text    = @"1900";
    [self joinMulticastGroup];

  } else {

    self.addressValue.text = [kBaseURL substringFromIndex:7];
    self.portValue.text    = @"80";
    self.baseURL = [NSURL URLWithString:(NSString *)kBaseURL];

  }

}

/// sendRequestWithText:
/// @param text description
- (void)sendRequestWithText:(NSString *)text {

  NSURL * url = [NSURL URLWithString:text relativeToURL:self.baseURL];
  NSURLRequest * request = [NSURLRequest requestWithURL:url];
  self.deviceConnection = [NSURLConnection connectionWithRequest:request delegate:self];

}

/// appendLogMessage:
/// @param message description
- (void)appendLogMessage:(NSString *)message {

  static NSDictionary    * msgAttrs = nil;
  static NSDictionary    * tmsAttrs = nil;

  static dispatch_once_t   onceToken;
  dispatch_once(&onceToken, ^{

    msgAttrs = @{ NSFontAttributeName : [UIFont fontWithName:@"User-Medium" size:15.0],
                  NSForegroundColorAttributeName : [WhiteColor colorWithAlphaComponent:0.75] };
    tmsAttrs = @{ NSFontAttributeName : [UIFont fontWithName:@"User-MediumCameo" size:14.0],
                  NSForegroundColorAttributeName : [WhiteColor colorWithAlphaComponent:0.5] };

  });

  [self appendString:message stringAttributes:msgAttrs timestampAttributes:tmsAttrs];

}

/// appendMessage:
/// @param message description
- (void)appendMessage:(NSString *)message {

  assert(IsMainQueue);

  static NSDictionary    * msgAttrs = nil;
  static NSDictionary    * tmsAttrs = nil;
  static dispatch_once_t   onceToken;

  dispatch_once(&onceToken, ^{

    msgAttrs = @{ NSFontAttributeName : [UIFont fontWithName:@"User-Medium" size:15.0],
                  NSForegroundColorAttributeName : WhiteColor };

    tmsAttrs = @{ NSFontAttributeName : [UIFont fontWithName:@"User-MediumCameo" size:14.0],
                  NSForegroundColorAttributeName : WhiteColor };
  });

  [self appendString:message stringAttributes:msgAttrs timestampAttributes:tmsAttrs];

}

/// appendString:stringAttributes:timestampAttributes:
/// @param string description
/// @param stringAttributes description
/// @param timestampAttributes description
- (void)appendString:(NSString *)string
    stringAttributes:(NSDictionary *)stringAttributes
 timestampAttributes:(NSDictionary *)timestampAttributes
{

  static NSDateFormatter * df = nil;
  static dispatch_once_t onceToken;

  dispatch_once(&onceToken, ^{

    df = [NSDateFormatter new];
    [df setDateFormat:@"_H•mm•ss.SSS_"];

  });

  [MainQueue addOperationWithBlock:^{

    NSUInteger len = 0;

    NSString           * time     = [[df stringFromDate:[NSDate date]] stringByAppendingString:@"\n"];
    NSAttributedString * attrTime = [NSAttributedString attributedStringWithString:time
                                                                        attributes:timestampAttributes];

    len += [attrTime length];

    NSString           * msg     = [string stringByAppendingString:@"\n\n"];
    NSAttributedString * attrMsg = [NSAttributedString attributedStringWithString:msg
                                                                       attributes:stringAttributes];
    len += [attrMsg length];


    NSMutableAttributedString * attrTxt = [self.messages.attributedText mutableCopy];
    [attrTxt appendAttributedString:attrTime];
    [attrTxt appendAttributedString:attrMsg];
    self.messages.attributedText = attrTxt;

    NSRange vis = NSMakeRange(0, [attrTxt length]);
    vis.location = vis.length - len;
    vis.length   = len;

    [self.messages scrollRangeToVisible:vis];

  }];

}

/// joinMulticastGroup
- (void)joinMulticastGroup {

  dispatch_queue_t q = dispatch_queue_create("com.moondeerstudios.isyclient", DISPATCH_QUEUE_CONCURRENT);

  dispatch_fd_t fd = self.groupFileDescriptor;
  if (!fd > 0) return;

  self.groupSource = dispatch_source_create(DISPATCH_SOURCE_TYPE_READ, fd, 0, q);
  if (!self.groupSource) return;

  __weak ViewController * weakself = self;

  // add event handler for multicast group message receiving
  dispatch_source_set_event_handler(_groupSource, ^{

    if (StringIsNotEmpty(weakself.location)) {
      NSLog(@"canceling source since we have a location already…");
      dispatch_source_cancel(weakself.groupSource);
      return;
    }

    [MainQueue addOperationWithBlock:^{

      [weakself appendLogMessage:@"receiving…"];

    }];

    ssize_t bytesAvailable = dispatch_source_get_data(weakself.groupSource);

    if (bytesAvailable) {

      char msg[bytesAvailable + 1];
      ssize_t bytesRead = read(fd, msg, bytesAvailable);

      if (bytesRead < 0) {

        NSLog(@"read failed: %i - %s", errno, strerror(errno));

        [MainQueue addOperationWithBlock:^{

          [weakself appendLogMessage:@"read failed, canceling…"];

        }];

        dispatch_source_cancel(weakself.groupSource);

      } else {

        msg[bytesAvailable] = '\0';
        NSString * message = @(msg);
        [MainQueue addOperationWithBlock:^{
          __strong NSString * messageCopy = [message copy];
          [weakself appendMessage:messageCopy];
        }];

        MSDictionary * entries =
        [MSDictionary dictionaryByParsingArray:[message matchingSubstringsForRegEx:@"^[A-Z]+:.*(?=\\r)"]];

        NSString * location = entries[@"LOCATION"];

        if (StringIsNotEmpty(location)) {

          weakself.location = location;
          [weakself appendLogMessage:@"location received"];

          // Create request with location url
          NSURLRequest * request = [NSURLRequest requestWithURL:[NSURL URLWithString:location]];

          // Get the device description
          [NSURLConnection sendAsynchronousRequest:request
                                             queue:MainQueue
                                 completionHandler:^(NSURLResponse * response, NSData * data, NSError * error)
           {

             if (!MSHandleErrors(error) && [response isKindOfClass:[NSHTTPURLResponse class]] && data) {

               MSDictionary * parsedXML = [MSDictionary dictionaryByParsingXML:data];
               [weakself appendMessage:[parsedXML formattedDescription]];

               NSString * baseURL = parsedXML[@"URLBase"];

               if (StringIsNotEmpty(baseURL)) weakself.baseURL = [NSURL URLWithString:baseURL];

             }

           }];
        }

      }
    }

  });

  // add cancel handler to clean up multicast group resources
  dispatch_source_set_cancel_handler(weakself.groupSource, ^{

    [MainQueue addOperationWithBlock:^{

      NSLog(@"closing multicast file descriptor…");
      [weakself appendLogMessage:@"closing connection…"];
      close(fd);
      weakself.groupSource = nil;

    }];

  });

  // add registration handler to log setup completion of multicast group source
  dispatch_source_set_registration_handler(weakself.groupSource, ^{

    [MainQueue addOperationWithBlock:^{

      [weakself appendLogMessage:@"ready to receive"];
      NSLog(@"multicast source setup complete");

    }];

  });

  // resume the multicast group source to connect and begin receiving beacons
  [self appendLogMessage:@"resuming multicast source…"];
  dispatch_resume(self.groupSource);


}

/// groupFileDescriptor
/// @return dispatch_fd_t
- (dispatch_fd_t)groupFileDescriptor {

  // Get the address info

  struct sockaddr * socketAddress;
  socklen_t         socketAddressLength = 0;
  int               error;
  struct addrinfo   socketHints, * resolve;

  memset(&socketHints, 0, sizeof(struct addrinfo));
  socketHints.ai_family   = AF_UNSPEC;
  socketHints.ai_socktype = SOCK_DGRAM;

  const char * address = [self.addressValue.text UTF8String];
  const char * port    = [self.portValue.text UTF8String];

  error = getaddrinfo(address, port, &socketHints, &resolve);

  if (error) {

    NSLog(@"error getting address info for %s, %s: %s", address, port, gai_strerror(error));
    return -1;

  }

  // Resolve into a useable socket

  dispatch_fd_t socketFileDescriptor = -1;

  do {

    socketFileDescriptor = socket(resolve->ai_family, resolve->ai_socktype, resolve->ai_protocol);

    if (socketFileDescriptor >= 0) { // success

      socketAddress = malloc(resolve->ai_addrlen);
      memcpy(socketAddress, resolve->ai_addr, resolve->ai_addrlen);
      socketAddressLength = resolve->ai_addrlen;

      break;
    }

  } while ((resolve = resolve->ai_next) != NULL);

  freeaddrinfo(resolve);

  if (socketAddress == NULL || socketFileDescriptor < 0) { // loop broke on NULL

    NSLog(@"error creating multicast socket for %s, %s", address, port);
    return -1;
  }

  // Bind socket to multicast address info

  if (bind(socketFileDescriptor, socketAddress, socketAddressLength) < 0) {

    close(socketFileDescriptor);
    free(socketAddress);

    NSLog(@"failed to bind multicast socket: %d - %s...closing socket", errno, strerror(errno));
    return -1;
  }

  // Join multicast group

  switch (socketAddress->sa_family) {

    case AF_INET: {

      struct ip_mreq mreq;

      memcpy(&mreq.imr_multiaddr,
             &((const struct sockaddr_in *)socketAddress)->sin_addr,
             sizeof(struct in_addr));

      mreq.imr_interface.s_addr = htonl(INADDR_ANY);

      error = setsockopt(socketFileDescriptor, IPPROTO_IP, IP_ADD_MEMBERSHIP, &mreq, sizeof(mreq));

    } break;

    case AF_INET6: {

      struct ipv6_mreq mreq6;

      memcpy(&mreq6.ipv6mr_multiaddr,
             &((const struct sockaddr_in6 *)socketAddress)->sin6_addr,
             sizeof(struct in6_addr));

      mreq6.ipv6mr_interface = 0;

      error = setsockopt(socketFileDescriptor, IPPROTO_IPV6, IPV6_JOIN_GROUP, &mreq6, sizeof(mreq6));

    } break;

    default: break;

  }

  if (error < 0) {

    close(socketFileDescriptor);
    free(socketAddress);

    NSLog(@"failed to join multicast group: %d - %s...closing socket", errno, strerror(errno));

    return -1;
  }

  free(socketAddress);

  return socketFileDescriptor;

}

/// baseURL
/// @return NSURL *
- (NSURL *)baseURL {
  NSURL * value = nil;
  @synchronized(self) {
    value = _baseURL;
  }
  return value;
}

/// setBaseURL:
/// @param baseURL description
- (void)setBaseURL:(NSURL *)baseURL {
  @synchronized(self) {
    _baseURL = baseURL;
    assert(IsMainQueue);
    self.addressValue.text = [_baseURL.absoluteString substringFromIndex:7];
    self.portValue.text    = @"80";
  }
}


////////////////////////////////////////////////////////////////////////////////
#pragma mark - NSURLConnectionDelegate
////////////////////////////////////////////////////////////////////////////////


/// connection:didFailWithError:
/// @param connection description
/// @param error description
- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
  MSHandleErrors(error);
  assert(IsMainQueue);
  [self appendLogMessage:error.localizedDescription];
}

/// connection:willSendRequestForAuthenticationChallenge:
/// @param connection description
/// @param challenge description
- (void)                         connection:(NSURLConnection *)connection
  willSendRequestForAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge
{
  MSLogDebug(@"challenge: %@", [challenge debugDescription]);
  NSURLCredential * credential = [NSURLCredential credentialWithUser:@"moondeer"
                                                            password:@"1bluebear"
                                                         persistence:NSURLCredentialPersistenceForSession];
  [challenge.sender useCredential:credential forAuthenticationChallenge:challenge];
}


////////////////////////////////////////////////////////////////////////////////
#pragma mark - NSURLConnectionDataDelegate
////////////////////////////////////////////////////////////////////////////////


/// connection:didReceiveData:
/// @param connection description
/// @param data description
- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {

  MSDictionary * parsedXML = [MSDictionary dictionaryByParsingXML:data];
  MSLogDebug(@"parsed response: %@", [parsedXML formattedDescription]);
  [self appendMessage:[parsedXML formattedDescription]];

}


////////////////////////////////////////////////////////////////////////////////
#pragma mark - UITextFieldDelegate
////////////////////////////////////////////////////////////////////////////////

/// textFieldShouldEndEditing:
/// @param textField description
/// @return BOOL
- (BOOL)textFieldShouldEndEditing:(UITextField *)textField {

  NSString * text = [textField.text hasPrefix:@"/"] ? [textField.text substringFromIndex:1] : textField.text;
  [self sendRequestWithText:text];

  return YES;
}

@end
