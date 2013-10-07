//
// Manufacturer.m
// Remote
//
// Created by Jason Cardwell on 7/7/12.
// Copyright (c) 2012 Moondeer Studios. All rights reserved.
//

#import "Manufacturer.h"
#import "BankGroup.h"

@implementation Manufacturer

@dynamic codesets, codes, devices;

+ (instancetype)manufacturerWithName:(NSString *)name context:(NSManagedObjectContext *)context
{
    assert(name && context);

    __block Manufacturer * manufacturer = nil;

    [context performBlockAndWait:
     ^{
         manufacturer = [self MR_findFirstByAttribute:@"info.name"
                                            withValue:name
                                            inContext:context];
         if (!manufacturer)
         {
             manufacturer = [self MR_createInContext:context];
             manufacturer.info.name = name;
         }
     }];

    return manufacturer;
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark - Bankable
////////////////////////////////////////////////////////////////////////////////

+ (NSString *)directoryLabel { return @"Manufacturers"; }

+ (BankFlags)bankFlags { return (BankDetail|BankNoSections|BankEditable); }

- (BOOL)isEditable { return ([super isEditable] && self.user); }

@end
