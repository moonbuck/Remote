//
// RemoteController.m
// Remote
//
// Created by Jason Cardwell on 7/21/11.
// Copyright (c) 2011 Moondeer Studios. All rights reserved.
//

#import "RemoteController.h"
#import "Activity.h"
#import "RemoteElement_Private.h"
#import "Constraint.h"
#import "ComponentDeviceConfiguration.h"
#import "Command.h"
#import "CoreDataManager.h"

static int ddLogLevel   = LOG_LEVEL_DEBUG;
static int msLogContext = (LOG_CONTEXT_REMOTE | LOG_CONTEXT_FILE | LOG_CONTEXT_CONSOLE);

#pragma unused(ddLogLevel,msLogContext)

static NSURL * sharedRemoteControllerURI = nil;


@interface RemoteController (CoreDataGeneratedAccessors)

@property (nonatomic, strong, readwrite)   Remote      * primitiveHomeRemote;
@property (nonatomic, strong, readwrite)   Remote      * primitiveCurrentRemote;
@property (nonatomic, strong, readwrite)   Activity    * primitiveCurrentActivity;
@property (nonatomic, strong, readwrite)   NSSet       * primitiveActivities;
@property (nonatomic, strong, readwrite)   ButtonGroup * primitiveTopToolbar;

@end

@implementation RemoteController

@dynamic currentRemote, currentActivity, homeRemote, topToolbar;


+ (RemoteController *)remoteController:(NSManagedObjectContext *)context {
  if (sharedRemoteControllerURI) { return [self objectForURI:sharedRemoteControllerURI context:context]; }
  else {
    RemoteController * controller = [self findFirstInContext:context];
    if (!controller) controller = [self createInContext:context];
    sharedRemoteControllerURI = controller.permanentURI;
    return controller;
  }
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark Remotes
////////////////////////////////////////////////////////////////////////////////

- (Remote *)currentRemote {
  Remote * currentRemote = nil;

  [self willAccessValueForKey:@"currentRemote"];
  currentRemote = self.primitiveCurrentRemote;
  [self didAccessValueForKey:@"currentRemote"];

  return currentRemote ?: self.homeRemote;
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark Activities
////////////////////////////////////////////////////////////////////////////////


- (void)setCurrentActivity:(Activity *)currentActivity {
  if ([self.activities containsObject:currentActivity] && self.primitiveCurrentActivity != currentActivity) {
    [self willChangeValueForKey:@"currentActivity"];
    [self.currentActivity haltActivity];
    self.primitiveCurrentActivity = currentActivity;
    [self didChangeValueForKey:@"currentActivity"];
  }
}

- (NSArray *)activities { return [Activity findAllInContext:self.managedObjectContext]; }


////////////////////////////////////////////////////////////////////////////////
#pragma mark JSON export
////////////////////////////////////////////////////////////////////////////////

- (MSDictionary *)JSONDictionary {
  MSDictionary * dictionary = [super JSONDictionary];

  dictionary[@"homeRemote.uuid"]      = CollectionSafe(self.homeRemote.commentedUUID);
  dictionary[@"currentRemote.uuid"]   = CollectionSafe(self.currentRemote.commentedUUID);
  dictionary[@"currentActivity.uuid"] = CollectionSafe(self.currentActivity.commentedUUID);
  dictionary[@"topToolbar"]           = CollectionSafe(self.topToolbar.JSONDictionary);
  id activities = CollectionSafeSelfKeyPathValue(@"activities.JSONDictionary");

  if (isSetKind(activities)) {
    NSMutableArray * activitiesArray = [[(NSSet *)activities allObjects] mutableCopy];

    [activitiesArray sortUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"name"
                                                                          ascending:YES]]];
    dictionary[@"activities"] = activitiesArray;
  }

  [dictionary compact];
  [dictionary compress];

  return dictionary;
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark Importing
////////////////////////////////////////////////////////////////////////////////

- (void)updateWithData:(NSDictionary *)data {
  /*
     "uuid": "01844614-744C-4664-BF8F-ABF948CE5996",
     "homeRemoteUUID": "B0EA5B35-5CF6-40E9-B302-0F164D4A7ADD", // Home Screen
     "topToolbar": { **ButtonGroup** },
     "activities": [ **Activity** ]
   */

  [super updateWithData:data];

  NSManagedObjectContext * moc        = self.managedObjectContext;
  Remote                 * homeRemote = [Remote importObjectFromData:data[@"home-remote"] context:moc];
  ButtonGroup            * topToolbar = [ButtonGroup importObjectFromData:data[@"top-toolbar"] context:moc];

  //TODO: Decide whether to import `currentRemote` and/or `currentActivity`

  self.homeRemote = homeRemote ?: self.homeRemote;
  self.topToolbar = topToolbar ?: self.topToolbar;

}

@end
