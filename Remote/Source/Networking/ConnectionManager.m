//
// ConnectionManager.m
// Remote
//
// Created by Jason Cardwell on 7/15/11.
// Copyright 2011 Moondeer Studios. All rights reserved.
//
#import "ConnectionManager_Private.h"
#import <objc/runtime.h>

////////////////////////////////////////////////////////////////////////////////
#pragma mark - Class Variables, Externs
////////////////////////////////////////////////////////////////////////////////

static int ddLogLevel   = LOG_LEVEL_DEBUG;
static int msLogContext = NETWORKING_F_C;

static const ConnectionManager * connectionManager = nil;

MSKIT_STRING_CONST   CMDevicesUserDefaultsKey         = @"CMDevicesUserDefaultsKey";
MSKIT_STRING_CONST   CMNetworkDeviceKey               = @"CMNetworkDeviceKey";
MSKIT_STRING_CONST   CMConnectionStatusNotification   = @"CMConnectionStatusNotification";
MSKIT_STRING_CONST   CMConnectionStatusWifiAvailable  = @"CMConnectionStatusWifiAvailable";
MSKIT_STRING_CONST   CMCommandDidCompleteNotification = @"CMCommandDidCompleteNotification";

////////////////////////////////////////////////////////////////////////////////
#pragma mark - ConnectionManager Implementation
////////////////////////////////////////////////////////////////////////////////

@implementation ConnectionManager

+ (const ConnectionManager *)connectionManager
{
    static dispatch_once_t pred = 0;
    dispatch_once(&pred, ^{
        connectionManager = [self new];

        // initialize settings
        connectionManager->_flags.autoConnect = [SettingsManager boolForSetting:kAutoConnectKey];
        connectionManager->_flags.simulateCommandSuccess = [UserDefaults boolForKey:@"simulate"];
        connectionManager->_flags.autoListen = YES;

        // initialize reachability
        connectionManager->_reachability =
        [MSNetworkReachability
         reachabilityWithCallback:
         ^(SCNetworkReachabilityFlags flags)
         {
             BOOL wifi = (   (flags & kSCNetworkReachabilityFlagsIsDirect)
                          && (flags & kSCNetworkReachabilityFlagsReachable));

             connectionManager->_flags.wifiAvailable = wifi;

             [NotificationCenter
              postNotificationName:CMConnectionStatusNotification
              object:self
              userInfo:@{ CMConnectionStatusWifiAvailable : @(wifi) }];
         }];

        // get initial reachability status and try connecting to the default device
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 2.0 * NSEC_PER_SEC),
                       dispatch_get_main_queue(),
                       ^{
                           [connectionManager->_reachability refreshFlags];
                           if (connectionManager->_flags.autoConnect)
                           {
                               if (![GlobalCacheConnectionManager connectWithDevice:nil])
                               {
                                   MSLogDebugTag(@"(autoConnect|autoListen) connect failed");
                                   if (connectionManager->_flags.autoListen)
                                       [GlobalCacheConnectionManager detectNetworkDevices];
                               }

                               else MSLogDebugTag(@"(autoConnect) default device connected");
                           }
                       });
    });
    return connectionManager;
}

+ (BOOL)resolveClassMethod:(SEL)sel
{
    BOOL isResolved = NO;

    Method instanceMethod = class_getInstanceMethod(self, sel);
    if (!instanceMethod) return [super resolveClassMethod:sel];

    // how many arguments does it take?
    unsigned numberOfArgs = method_getNumberOfArguments(instanceMethod);

        // get type encodings
    const char * typeEncodings = method_getTypeEncoding(instanceMethod);
    switch (typeEncodings[0]) {
        case 'c':
        {
            assert(numberOfArgs == 2);
            BOOL (*instanceImp)(id,SEL);
            instanceImp = (BOOL (*)(id,SEL))method_getImplementation(instanceMethod);
            IMP classImp = imp_implementationWithBlock(^(id _self) {
                return instanceImp([ConnectionManager connectionManager], sel);
            });
            isResolved = class_addMethod(objc_getMetaClass("ConnectionManager"),
                                         sel,
                                         classImp,
                                         typeEncodings);
        } break;

        case 'v':
        {
            if (numberOfArgs == 2)
            {
                void (*instanceImp)(id,SEL);
                instanceImp = (void (*)(id,SEL))method_getImplementation(instanceMethod);
                IMP classImp = imp_implementationWithBlock(^(id _self) {
                    instanceImp([ConnectionManager connectionManager], sel);
                });
                isResolved = class_addMethod(objc_getMetaClass("ConnectionManager"),
                                             sel,
                                             classImp,
                                             typeEncodings);
            }

            else
            {
                assert(numberOfArgs == 4);
                void (*instanceImp)(id,SEL,id,id);
                instanceImp = (void (*)(id,SEL,id,id))method_getImplementation(instanceMethod);
                IMP classImp = imp_implementationWithBlock(^(id _self, id arg1, id arg2) {
                    instanceImp([ConnectionManager connectionManager], sel, arg1, arg2);
                });
                isResolved = class_addMethod(objc_getMetaClass("ConnectionManager"),
                                             sel,
                                             classImp,
                                             typeEncodings);
            }
        } break;
            
        default:
            assert(NO);
            break;
    }

    return isResolved;
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark - Sending commands
////////////////////////////////////////////////////////////////////////////////

- (void)sendCommand:(NSManagedObjectID *)commandID completion:(RECommandCompletionHandler)completion
{
    if (!_flags.wifiAvailable) { MSLogWarnTag(@"wifi not available"); return; }


    BOOL   success = NO, finished = NO;
    NSManagedObject * command = [[NSManagedObjectContext MR_defaultContext] existingObjectWithID:commandID
                                                                                    error:nil];

    if ([command isKindOfClass:[RESendIRCommand class]])
    {
        static NSUInteger nextTag = 0;
        RESendIRCommand * sendIRCommand = (RESendIRCommand *)command;
        NSString * cmd = sendIRCommand.commandString;
        MSLogDebugTag(@"sendIRCommand:%@", [sendIRCommand shortDescription]);

        if (StringIsEmpty(cmd))
        {
            MSLogWarnTag(@"cannot send empty or nil command");
            if (completion) completion(YES, NO);
        }

        else
        {
            NSUInteger tag = (++nextTag%100) + 1;
            if (_flags.simulateCommandSuccess && completion)
            {
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)),
                               dispatch_get_main_queue(),
                               ^(void){ completion(YES, YES); });
            }
            
            else [GlobalCacheConnectionManager sendCommand:cmd
                                                       tag:tag
                                                    device:nil
                                                completion:completion];
        }
    }

    else if ([command isKindOfClass:[REHTTPCommand class]])
    {
        NSURL * url = ((REHTTPCommand*)command).url;

        if (StringIsEmpty([url absoluteString])) MSLogWarnTag(@"cannot send empty or nil command");

        else
        {
            MSLogDebugTag(@"sending URL command:%@", command);

            if (_flags.simulateCommandSuccess) { success = YES; finished = YES; }

            else
            {
                NSURLRequest * request = [NSURLRequest requestWithURL:url];
                success  = ([NSURLConnection connectionWithRequest:request delegate:nil] != nil);
                finished = YES;
            }
        }

        if (completion) completion(finished, success);
    }
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark - Reachability
////////////////////////////////////////////////////////////////////////////////

- (BOOL)isWifiAvailable { return _flags.wifiAvailable; }

///////////////////////////////////////////////////////////////////////////////
#pragma mark - Logging
////////////////////////////////////////////////////////////////////////////////

- (void)logStatus { MSLogInfoTag(@"%@", [GlobalCacheConnectionManager statusDescription]); }

+ (int)ddLogLevel { return ddLogLevel; }

+ (void)ddSetLogLevel:(int)logLevel { ddLogLevel = logLevel; }

+ (int)msLogContext { return msLogContext; }

+ (void)msSetLogContext:(int)logContext { msLogContext = logContext; }

@end
