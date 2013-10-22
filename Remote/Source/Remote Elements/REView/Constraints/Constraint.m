//
// Constraint.m
// Remote
//
// Created by Jason Cardwell on 1/21/13.
// Copyright (c) 2013 Moondeer Studios. All rights reserved.
//

#import "Constraint.h"
#import "ConstraintManager.h"
#import "RemoteElement_Private.h"
#import "RemoteElementView_Private.h"

@interface Constraint ()

@property (nonatomic, assign, readwrite) int16_t         firstAttribute;
@property (nonatomic, assign, readwrite) int16_t         secondAttribute;
@property (nonatomic, assign, readwrite) int16_t         relation;
@property (nonatomic, assign, readwrite) float           multiplier;
@property (nonatomic, strong, readwrite) RemoteElement * firstItem;
@property (nonatomic, strong, readwrite) RemoteElement * secondItem;

@end

////////////////////////////////////////////////////////////////////////////////
#pragma mark - REConstraint
////////////////////////////////////////////////////////////////////////////////

@implementation Constraint
@dynamic firstAttribute, secondAttribute, multiplier, constant, firstItem, secondItem, relation, priority, owner, tag, key;

////////////////////////////////////////////////////////////////////////////////
#pragma mark Initializer
////////////////////////////////////////////////////////////////////////////////

+ (Constraint *)constraintWithItem:(RemoteElement *)element1
                           attribute:(NSLayoutAttribute)attr1
                           relatedBy:(NSLayoutRelation)relation
                              toItem:(RemoteElement *)element2
                           attribute:(NSLayoutAttribute)attr2
                          multiplier:(CGFloat)multiplier
                            constant:(CGFloat)c
{
    assert(  ValueIsNotNil(element1)
           && attr1 && (  !element2
                        || ValueIsNotNil(element2)));

    __block Constraint * constraint = nil;
    NSManagedObjectContext * context = element1.managedObjectContext;

    [context performBlockAndWait:^{
        constraint = [NSEntityDescription
                      insertNewObjectForEntityForName:@"Constraint"
                      inManagedObjectContext:context];
        if (constraint) {
            constraint.firstAttribute = attr1;
            constraint.relation = relation;
            constraint.secondItem = element2;
            constraint.secondAttribute = attr2;
            constraint.multiplier = multiplier;
            constraint.constant = c;
            constraint.firstItem = element1;
        }
     }];

    return constraint;
}

+ (Constraint *)constraintWithAttributeValues:(NSDictionary *)attributes
{
    return [self constraintWithItem:attributes[@"firstItem"]
                          attribute:NSUIntegerValue(attributes[@"firstAttribute"])
                          relatedBy:NSUIntegerValue(attributes[@"relation"])
                             toItem:NilSafeValue(attributes[@"secondItem"])
                          attribute:NSUIntegerValue(attributes[@"secondAttribute"])
                         multiplier:CGFloatValue(attributes[@"multiplier"])
                           constant:CGFloatValue(attributes[@"constant"])];
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark Properties
////////////////////////////////////////////////////////////////////////////////

- (LayoutConfiguration *)configuration { return self.firstItem.layoutConfiguration; }

- (BOOL)isStaticConstraint { return !self.secondItem; }

- (BOOL)hasAttributeValues:(NSDictionary *)values {
    id         firstItem       = values[@"firstItem"];
    id         secondItem      = values[@"secondItem"];
    NSNumber * firstAttribute  = values[@"firstAttribute"];
    NSNumber * secondAttribute = values[@"secondAttribute"];
    NSNumber * relation        = values[@"relation"];
    NSNumber * multiplier      = values[@"multiplier"];
    NSNumber * constant        = values[@"constant"];
    NSNumber * priority        = values[@"priority"];
    id         owner           = values[@"owner"];

    return (   (   !firstItem
                || (  [firstItem isKindOfClass:[NSString class]]
                    ? [self.firstItem.uuid isEqualToString:firstItem]
                    : self.firstItem == firstItem))
            && (!firstAttribute || self.firstAttribute == CGFloatValue(firstAttribute))
            && (!relation || self.relation == NSIntegerValue(relation))
            && (   !secondItem
                || (  [secondItem isKindOfClass:[NSString class]]
                    ? [self.secondItem.uuid isEqualToString:secondItem]
                    : self.secondItem == secondItem))
            && (!secondAttribute || self.secondAttribute == CGFloatValue(secondAttribute))
            && (!multiplier || self.multiplier == CGFloatValue(multiplier))
            && (!constant || self.constant == CGFloatValue(constant))
            && (!priority || self.priority == CGFloatValue(priority))
            && (   !owner
                || (  [owner isKindOfClass:[NSString class]]
                    ? [self.owner.uuid isEqualToString:owner]
                    : self.owner == owner))
            );
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark Logging
////////////////////////////////////////////////////////////////////////////////

- (NSString *)committedValuesDescription
{
    NSArray * attributeKeys = @[@"firstItem",
                                @"firstAttribute",
                                @"relation",
                                @"secondItem",
                                @"secondAttribute",
                                @"multiplier",
                                @"constant",
                                @"priority"];

    NSDictionary * attributes = [self committedValuesForKeys:attributeKeys];

    NSString * firstItem      = [((RemoteElement *)attributes[@"firstItem"]).name
                                 camelCaseString];
    NSString * firstAttribute = [NSLayoutConstraint pseudoNameForAttribute:
                                 [attributes[@"firstAttribute"] integerValue]];
    NSString * relation       = [NSLayoutConstraint pseudoNameForRelation:
                                 [attributes[@"relation"] integerValue]];
    NSString * secondItem     = [((RemoteElement *)NilSafeValue(attributes[@"secondItem"])).name
                                 camelCaseString];
    NSString * secondAttribute = (NSIntegerValue(attributes[@"secondAttribute"])
                                  ? [NSLayoutConstraint pseudoNameForAttribute:
                                     [attributes[@"secondAttribute"] integerValue]]
                                  : nil);
    NSString * multiplier = ([(NSNumber *)attributes[@"multiplier"] floatValue] == 1.0f
                             ? nil
                             :StripTrailingZeros($(@"%f", [(NSNumber *)attributes[@"multiplier"] floatValue])));
    NSString * constant = ([(NSNumber *)attributes[@"constant"] floatValue] == 0.0f
                           ? nil
                           :StripTrailingZeros($(@"%f", [(NSNumber *)attributes[@"constant"] floatValue])));
    NSString * priority = ([(NSNumber *)attributes[@"priority"] integerValue] == UILayoutPriorityRequired
                           ? nil
                           :$(@"%i", [attributes[@"priority"] integerValue]));
    NSMutableString * stringRep = [NSMutableString stringWithFormat:@"%@.%@ %@ ",
                                   firstItem, firstAttribute, relation];

    if (secondItem && secondAttribute) {
        [stringRep appendFormat:@"%@.%@", secondItem, secondAttribute];
        if (multiplier) [stringRep appendFormat:@" * %@", multiplier];
        if (constant) {
            if (self.constant < 0) {
                constant = [constant substringFromIndex:1];
                [stringRep appendString:@" - "];
            } else
                [stringRep appendString:@" + "];
        }
    }
    if (constant) [stringRep appendString:constant];
    if (priority) [stringRep appendFormat:@" %@", priority];

    return stringRep;
}

- (NSDictionary * )JSONDictionary
{
    MSDictionary * dictionary = [[super JSONDictionary] mutableCopy];

    if (self.tag) dictionary[@"tag"] = @(self.tag);
    dictionary[@"key"] = CollectionSafeValue(self.key);
    dictionary[@"firstAttribute"] = [NSLayoutConstraint pseudoNameForAttribute:self.firstAttribute];
    dictionary[@"secondAttribute"] = [NSLayoutConstraint pseudoNameForAttribute:self.secondAttribute];
    dictionary[@"relation"] = [NSLayoutConstraint pseudoNameForRelation:self.relation];
    if (self.multiplier != 1.0f) dictionary[@"multiplier"] = @(self.multiplier);
    if (self.constant) dictionary[@"constant"] = @(self.constant);
    dictionary[@"firstItem"] = self.firstItem.uuid;
    dictionary[@"secondItem"] = CollectionSafeValue(self.secondItem.uuid);
    dictionary[@"owner"] = self.owner.uuid;
    if (self.priority != UILayoutPriorityRequired) dictionary[@"priority"] = @(self.priority);

//    [dictionary removeKeysWithNullObjectValues];

    return dictionary;
}

- (NSString *)description {
    if (!self.managedObjectContext)
        return @"orphaned constraint";
    else if ([self isDeleted])
        return $(@"%@ <deleted>", [self committedValuesDescription]);

    NSArray * attributeKeys = @[@"firstItem",
                                @"firstAttribute",
                                @"relation",
                                @"secondItem",
                                @"secondAttribute",
                                @"multiplier",
                                @"constant",
                                @"priority"];

    NSDictionary * attributes = [self dictionaryWithValuesForKeys:attributeKeys];

    NSString * firstItem       = [((RemoteElement *)attributes[@"firstItem"]).name
                                  camelCaseString];
    NSString * firstAttribute  = [NSLayoutConstraint pseudoNameForAttribute:
                                  [attributes[@"firstAttribute"] integerValue]];
    NSString * relation        = [NSLayoutConstraint pseudoNameForRelation:
                                  [attributes[@"relation"] integerValue]];
    NSString * secondItem      = [((RemoteElement *)NilSafeValue(attributes[@"secondItem"])).name
                                  camelCaseString];
    NSString * secondAttribute = ([attributes[@"secondAttribute"] integerValue]
                                  ? [NSLayoutConstraint pseudoNameForAttribute:
                                     [attributes[@"secondAttribute"] integerValue]]
                                  : nil);
    NSString * multiplier = ([(NSNumber *)attributes[@"multiplier"] floatValue] == 1.0f
                             ? nil
                             :StripTrailingZeros($(@"%f", [(NSNumber *)attributes[@"multiplier"] floatValue])));
    NSString * constant = ([(NSNumber *)attributes[@"constant"] floatValue] == 0.0f
                           ? nil
                           :StripTrailingZeros($(@"%f", [(NSNumber *)attributes[@"constant"] floatValue])));
    NSString * priority = ([(NSNumber *)attributes[@"priority"] integerValue] == UILayoutPriorityRequired
                           ? nil
                           :$(@"@%i", [attributes[@"priority"] integerValue]));
    NSMutableString * stringRep = [NSMutableString stringWithFormat:@"%@.%@ %@ ",
                                   firstItem, firstAttribute, relation];

    if (secondItem && secondAttribute) {
        [stringRep appendFormat:@"%@.%@", secondItem, secondAttribute];
        if (multiplier) [stringRep appendFormat:@" * %@", multiplier];
        if (constant) {
            if (self.constant < 0) {
                constant = [constant substringFromIndex:1];
                [stringRep appendString:@" - "];
            } else
                [stringRep appendString:@" + "];
        }
    }
    if (constant) [stringRep appendString:constant];
    if (priority) [stringRep appendFormat:@" %@", priority];

    return stringRep;
}

@end

