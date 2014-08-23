//
// DelayCommand.m
// Remote
//
// Created by Jason Cardwell on 7/20/11.
// Copyright (c) 2011 Moondeer Studios. All rights reserved.
//
#import "Command_Private.h"

static int ddLogLevel = LOG_LEVEL_DEBUG;
static int msLogContext = (LOG_CONTEXT_COMMAND|LOG_CONTEXT_FILE|LOG_CONTEXT_CONSOLE);

@interface DelayCommandOperation : CommandOperation @end

@implementation DelayCommand

@dynamic duration;

+ (DelayCommand *)commandInContext:(NSManagedObjectContext *)context duration:(CGFloat)duration
{
    __block DelayCommand * delayCommand = nil;

    [context performBlockAndWait:
     ^{
         delayCommand = [self commandInContext:context];
         delayCommand.duration = @(duration);
     }];

    return delayCommand;
}

+ (instancetype)importObjectFromData:(NSDictionary *)data inContext:(NSManagedObjectContext *)moc {
    /*
     {
     "class": "delay",
     "duration": 6
     }
     */

    DelayCommand * delayCommand = [super importObjectFromData:data inContext:moc];

    if (!delayCommand) {

        delayCommand = [DelayCommand objectWithUUID:data[@"uuid"] context:moc];

        NSNumber * duration = data[@"duration"];
        if (duration) delayCommand.duration = duration;

    }

    return delayCommand;

}

- (MSDictionary *)JSONDictionary
{
    MSDictionary * dictionary = [super JSONDictionary];
    dictionary[@"uuid"] = NullObject;

    dictionary[@"duration"] = self.duration;

    [dictionary compact];
    [dictionary compress];

    return dictionary;
}


- (CommandOperation *)operation { return [DelayCommandOperation operationForCommand:self]; }

- (NSString *)shortDescription { return $(@"duration:%@",self.primitiveDuration); }

@end

@implementation DelayCommandOperation

- (void)main
{
    @try
    {
        CGFloat duration = ((DelayCommand *)_command).duration.floatValue;
        //TODO: Only sleep for small chunks and check for cancellation
        MSLogDebugTag(@"sleeping for %f seconds", duration);
        sleep(duration);
        MSLogDebugTag(@"k, I'm awake");
        _success = YES;
        [super main];
    }

    @catch(NSException * exception)
    {
        // Do not rethrow exceptions.
        MSLogErrorTag(@"wtf?");
    }
}

@end

