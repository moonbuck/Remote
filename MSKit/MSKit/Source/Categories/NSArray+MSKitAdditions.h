//
//  NSMutableArray+MSKitAdditions.h
//  MSKit
//
//  Created by Jason Cardwell on 5/24/11.
//  Copyright 2011 Moondeer Studios. All rights reserved.
//
#import <Foundation/Foundation.h>
#import "MSKitDefines.h"
#import "MSKitProtocols.h"

//typedef void(^NSArrayEnumerationBlock)(id obj, NSUInteger idx, BOOL *stop);
//typedef BOOL(^NSArrayPredicateBlock)  (id obj, NSUInteger idx, BOOL *stop);
//typedef id  (^NSArrayMappingBlock)    (id obj, NSUInteger idx);


@interface NSArray (MSKitAdditions) <MSJSONExport>

@property (nonatomic, readonly) BOOL isEmpty;

+ (NSArray *)arrayFromRange:(NSRange)range;
+ (NSArray *)arrayWithObject:(id)obj count:(NSUInteger)count;

@property (nonatomic, readonly) id JSONObject;

- (NSSet *)set;
- (NSUInteger)lastIndex;
- (NSOrderedSet *)orderedSet;


- (NSArray *)arrayByAddingObjects:(id)objects;
- (NSArray *)arrayByAddingKeysFromDictionary:(NSDictionary *)dictionary;
- (NSArray *)arrayByAddingValuesFromDictionary:(NSDictionary *)dictionary;
- (NSArray *)arrayByAddingObjectsFromSet:(NSSet *)set;
- (NSArray *)compacted;
- (NSArray *)arrayByAddingObjectsFromOrderedSet:(NSOrderedSet *)orderedSet;
- (NSArray *)filteredArrayUsingPredicateWithFormat:(NSString *)format,...;
- (NSArray *)filteredArrayUsingPredicateWithBlock:(BOOL (^)(id evaluatedObject,
                                                            NSDictionary * bindings))block;
- (NSArray *)filtered:(BOOL (^)(id evaluatedObject))block;
- (id)objectPassingTest:(BOOL (^)(id obj, NSUInteger idx))predicate;
- (NSArray *)objectsPassingTest:(BOOL (^)(id obj, NSUInteger idx, BOOL *stop))predicate;
- (NSArray *)flattened;
- (NSArray *)mapped:(id (^)(id obj, NSUInteger idx))block;

- (void)makeObjectsPerformSelectorBlock:(void (^)(id object))block;

@end


@interface NSMutableArray (MSKitAdditions)
+ (instancetype)arrayWithObject:(id)obj count:(NSUInteger)count;
+ (id)arrayWithNullCapacity:(NSUInteger)capacity;
- (void)filter:(BOOL (^)(id evaluatedObject))block;
- (void)map:(id (^)(id obj, NSUInteger idx))block;
- (void)replaceAllObjectsWithNull;
- (void)compact;
- (void)flatten;
@end

#define NSArrayOfVariableNames(...) \
_NSArrayOfVariableNames(@"" # __VA_ARGS__, __VA_ARGS__, nil)

MSEXTERN NSArray * _NSArrayOfVariableNames(NSString * commaSeparatedNamesString, ...);
