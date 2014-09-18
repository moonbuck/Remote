//
//  NDiTachDevice.m
//  Remote
//
//  Created by Jason Cardwell on 9/4/14.
//  Copyright (c) 2014 Moondeer Studios. All rights reserved.
//

#import "ITachDevice.h"
#import "ITachDeviceViewController.h"

static int ddLogLevel   = LOG_LEVEL_DEBUG;
static int msLogContext = LOG_CONTEXT_CONSOLE;
#pragma unused(ddLogLevel,msLogContext)

@interface ITachDevice ()

@property (nonatomic, copy, readwrite) NSString * make;
@property (nonatomic, copy, readwrite) NSString * model;
@property (nonatomic, copy, readwrite) NSString * status;
@property (nonatomic, copy, readwrite) NSString * configURL;
@property (nonatomic, copy, readwrite) NSString * revision;
@property (nonatomic, copy, readwrite) NSString * pcbPN;
@property (nonatomic, copy, readwrite) NSString * pkgLevel;
@property (nonatomic, copy, readwrite) NSString * sdkClass;

@end

@interface ITachDevice (CoreDataGenerated)

@property (nonatomic) NSString * primitiveMake;
@property (nonatomic) NSString * primitiveModel;
@property (nonatomic) NSString * primitiveStatus;
@property (nonatomic) NSString * primitiveConfigURL;
@property (nonatomic) NSString * primitiveRevision;
@property (nonatomic) NSString * primitivePcbPN;
@property (nonatomic) NSString * primitivePkgLevel;
@property (nonatomic) NSString * primitiveSdkClass;

@end


@implementation ITachDevice

@dynamic pcbPN, pkgLevel, sdkClass, make, model, status, configURL, revision;

/// detailViewController
/// @return ITachDeviceViewController *
- (ITachDeviceViewController *)detailViewController {
  return [ITachDeviceViewController controllerWithItem:self];
}

/// editingViewController
/// @return ITachDeviceViewController *
- (ITachDeviceViewController *)editingViewController {
  return [ITachDeviceViewController controllerWithItem:self editing:YES];
}


/// setModel:
/// @param model
- (void)setModel:(NSString *)model {
  [self willChangeValueForKey:@"model"];
  self.primitiveModel = model;
  [self didChangeValueForKey:@"model"];
  if (self.isNameAutoGenerated) {
    NSMutableString * name = [@"" mutableCopy];
    if (StringIsNotEmpty(self.make)) [name appendString:self.make];
    if (StringIsNotEmpty(model)) {
      if (StringIsNotEmpty(name)) [name appendString:@"-"];
      [name appendString:model];
    }
    if (StringIsNotEmpty(name)) [self setPrimitiveValue:name forKey:@"name"];
  }
}

/// setMake:
/// @param make
- (void)setMake:(NSString *)make {
  [self willChangeValueForKey:@"make"];
  self.primitiveMake = make;
  [self didChangeValueForKey:@"make"];
  if (self.isNameAutoGenerated) {
    NSMutableString * name = [@"" mutableCopy];
    if (StringIsNotEmpty(self.model)) [name appendString:self.model];
    if (StringIsNotEmpty(make)) {
      if (StringIsNotEmpty(name)) [name appendString:@"-"];
      [name appendString:make];
    }
    if (StringIsNotEmpty(name)) [self setPrimitiveValue:name forKey:@"name"];
  }
}

/// setConfigURL:
/// @param configURL
- (void)setConfigURL:(NSString *)configURL {

  [self willChangeValueForKey:@"configURL"];

  // Strip 'http://' if present
  self.primitiveConfigURL = ([configURL hasPrefix:@"http://"]
                             ? [configURL substringFromIndex:7]
                             : configURL);

  [self didChangeValueForKey:@"configURL"];


}

/// updateWithData:
/// @param data
- (void)updateWithData:(NSDictionary *)data {

  [super updateWithData:data];

  self.pcbPN      = data[@"pcb-pn"];
  self.pkgLevel   = data[@"pkg-level"];
  self.sdkClass   = data[@"sdk-class"];
  self.make       = data[@"make"];
  self.model      = data[@"model"];
  self.status     = data[@"status"];
  self.configURL  = data[@"config-url"];
  self.revision   = data[@"revision"];

}

/// JSONDictionary
/// @return MSDictionary *
- (MSDictionary *)JSONDictionary {

  MSDictionary * dictionary = [super JSONDictionary];

  dictionary[@"type"] = @"itach";

  SafeSetValueForKey(self.pcbPN,      @"pcb-pn",      dictionary);
  SafeSetValueForKey(self.pkgLevel,   @"pkg-level",   dictionary);
  SafeSetValueForKey(self.sdkClass,   @"sdk-class",   dictionary);
  SafeSetValueForKey(self.make,       @"make",        dictionary);
  SafeSetValueForKey(self.model,      @"model",       dictionary);
  SafeSetValueForKey(self.status,     @"status",      dictionary);
  SafeSetValueForKey(self.configURL,  @"config-url",   dictionary);
  SafeSetValueForKey(self.revision,   @"revision",    dictionary);

  return dictionary;

}

@end
