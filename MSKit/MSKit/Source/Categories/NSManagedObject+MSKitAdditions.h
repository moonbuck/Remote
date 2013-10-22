//
//  NSManagedObject+MSKitAdditions.h
//  MSKit
//
//  Created by Jason Cardwell on 3/3/13.
//  Copyright (c) 2013 Moondeer Studios. All rights reserved.
//
#import <CoreData/CoreData.h>
#import "MSKitDefines.h"

MSEXTERN_KEY(MSDefaultValueForContainingClass);

@interface NSManagedObject (MSKitAdditions)

- (id)committedValueForKey:(NSString *)key;
- (BOOL)hasChangesForKey:(NSString *)key;

- (NSURL *)permanentURI;

- (NSAttributeDescription *)attributeDescriptionForAttribute:(NSString *)attributeName;

- (id)defaultValueForAttribute:(NSString *)attributeName;

- (id)defaultValueForAttribute:(NSString *)attributeName forContainingClass:(NSString *)className;

- (instancetype)faultedObject;

@end

#define NSManagedObjectFromClass(CONTEXT)                               \
    [NSEntityDescription                                                \
        insertNewObjectForEntityForName:NSStringFromClass([self class]) \
                 inManagedObjectContext:CONTEXT]
