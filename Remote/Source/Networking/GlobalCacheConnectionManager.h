//
// GlobalCacheConnectionManager.h
// Remote
//
// Created by Jason Cardwell on 9/10/12.
// Copyright (c) 2012 Moondeer Studios. All rights reserved.
//
#import "RETypedefs.h"

@class RESendIRCommand;

MSKIT_EXTERN_STRING   NDiTachDeviceDiscoveryNotification;
MSKIT_EXTERN_STRING   NDDefaultiTachDeviceKey;

////////////////////////////////////////////////////////////////////////////////
#pragma mark - Global Caché Connection Manager
////////////////////////////////////////////////////////////////////////////////

@interface GlobalCacheConnectionManager : NSObject

/**
 * Returns shared singleton instance of `GlobalCacheConnectionManager`.
 */
+ (GlobalCacheConnectionManager *)sharedInstance;

/**
 * Join multicast group and listen for beacons broadcast by iTach devices.
 */
- (BOOL)detectNetworkDevices;

/**
 * Cease listening for beacon broadcasts and release resources.
 */
- (void)stopNetworkDeviceDetection;

/**
 * Attempts to connect with the device identified by the specified `uuid`.
 * @param uuid The uuid of the device with which to connect, or nil for the registered default device
 */
- (BOOL)connectWithDevice:(NSString *)uuid;

/**
 * Sends an IR command to the device identified by the specified `uuid`.
 * @param command The command string to be sent to the device for execution
 * @param tag Used to identify the command being sent in a later scope
 * @param uuid The uuid for the device to which the command will be sent
 * @return YES if command dispatched successfully, NO otherwise
 */
- (BOOL)sendCommand:(NSString *)command
                tag:(NSUInteger)tag
             device:(NSString *)uuid
         completion:(RECommandCompletionHandler)completion;

/// Whether socket is open to receive multicast group broadcast messages.
@property (nonatomic, readonly, getter = isDetectingNetworkDevices) BOOL detectingNetworkDevices;

/// Whether a socket connection has been estabilished with the default device.
@property (nonatomic, readonly, getter = isDefaultDeviceConnected) BOOL defaultDeviceConnected;

/// String containing description of the connecition manager's state and of any discovered devices.
@property (nonatomic, readonly) NSString * statusDescription;

/// The uuid identifying an iTach device to be registered as the default device.
@property (nonatomic, copy) NSString * defaultDeviceUUID;

@end

#define GCConnManager [GlobalCacheConnectionManager sharedInstance]
