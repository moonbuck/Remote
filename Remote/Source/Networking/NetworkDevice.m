//
// NetworkDevice.m
// Remote
//
// Created by Jason Cardwell on 9/25/12.
// Copyright (c) 2012 Moondeer Studios. All rights reserved.
//

#import "NetworkDevice.h"
#import "CoreDataManager.h"
#import "NDiTachDevice.h"
#import "ISYDevice.h"

static int ddLogLevel   = LOG_LEVEL_DEBUG;
static int msLogContext = LOG_CONTEXT_CONSOLE;
#pragma unused(ddLogLevel,msLogContext)


////////////////////////////////////////////////////////////////////////////////
#pragma mark - Abstract
////////////////////////////////////////////////////////////////////////////////


@interface NetworkDevice ()
@property (nonatomic, copy, readwrite) NSString * uniqueIdentifier;
@end

@implementation NetworkDevice

@dynamic uniqueIdentifier, componentDevices;

/// deviceExistsWithDeviceUUID:
/// @param identifier description
/// @return BOOL
+ (BOOL)deviceExistsWithUniqueIdentifier:(NSString *)identifier {
  return [self countOfObjectsWithPredicate:NSPredicateMake(@"uniqueIdentifer == %@", identifier)] > 0;
}

/// importObjectFromData:context:
/// @param data description
/// @param moc description
/// @return instancetype
+ (instancetype)importObjectFromData:(NSDictionary *)data context:(NSManagedObjectContext *)moc {
  if (self == [NetworkDevice class] && [@"itach" isEqualToString:data[@"type"]])
    return [NDiTachDevice importObjectFromData:data context:moc];
  else if (self == [NetworkDevice class] && [@"isy" isEqualToString:data[@"type"]])
    return [ISYDevice importObjectFromData:data context:moc];
  else
    return [super importObjectFromData:data context:moc];
}

/// updateWithData:
/// @param data description
- (void)updateWithData:(NSDictionary *)data {

  [super updateWithData:data];

  self.uniqueIdentifier = data[@"unique-identifier"];
  self.name             = data[@"name"];

}

/// networkDeviceForBeaconData:context:
/// @param message description
/// @param moc description
/// @return instancetype
+ (instancetype)networkDeviceFromDiscoveryBeacon:(NSString *)message context:(NSManagedObjectContext *)moc {
  return nil;
}

/// JSONDictionary
/// @return MSDictionary *
- (MSDictionary *)JSONDictionary {

  MSDictionary * dictionary = [super JSONDictionary];

  SafeSetValueForKey(self.name,             @"name",              dictionary);
  SafeSetValueForKey(self.uniqueIdentifier, @"unique-identifier", dictionary);


  return dictionary;

}

- (NSString *)multicastGroupAddress { return nil; }
- (NSString *)multicastGroupPort    { return nil; }

@end



