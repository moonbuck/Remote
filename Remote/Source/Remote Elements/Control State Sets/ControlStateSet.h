//
// ControlStateSet.h
// Remote
//
// Created by Jason Cardwell on 3/26/12.
// Copyright (c) 2012 Moondeer Studios. All rights reserved.
//
@import UIKit;
@import CoreData;
@import Foundation;
@import CocoaLumberjack;
@import MoonKit;
#import "MSRemoteMacros.h"
#import "ModelObject.h"
#import "RETypedefs.h"

////////////////////////////////////////////////////////////////////////////////
#pragma mark - ControlStateSet
////////////////////////////////////////////////////////////////////////////////

@interface ControlStateSet : ModelObject <NSCopying>

+ (BOOL)validState:(id)state;
+ (NSString *)propertyForState:(NSNumber *)state;
+ (NSUInteger)stateForProperty:(NSString *)property;
+ (NSSet *)validProperties;
+ (NSString *)attributeKeyFromKey:(id)key;

- (BOOL)isEmptySet;
- (NSDictionary *)dictionaryFromSetObjects:(BOOL)useJSONKeys;

- (NSArray *)allValues;

- (id)objectAtIndexedSubscript:(NSUInteger)state;
- (id)objectForKeyedSubscript:(NSString *)key;

- (void)setObject:(id)obj atIndexedSubscript:(NSUInteger)state;
- (void)setObject:(id)obj forKeyedSubscript:(NSString *)key;

//- (void)copyObjectsFromSet:(ControlStateSet *)set;

@end
