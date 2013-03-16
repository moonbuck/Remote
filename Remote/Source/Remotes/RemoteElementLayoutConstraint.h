//
// RemoteElementLayoutConstraint.h
// iPhonto
//
// Created by Jason Cardwell on 1/21/13.
// Copyright (c) 2013 Moondeer Studios. All rights reserved.
//
@class   RemoteElement;
@class   RemoteElementView;
@class   RemoteElementLayoutConfiguration;

@interface RemoteElementLayoutConstraint : NSManagedObject

@property (nonatomic, assign)           int16_t         tag;
@property (nonatomic, copy)             NSString      * key;
@property (nonatomic, copy,   readonly) NSString      * identifier;
@property (nonatomic, assign, readonly) int16_t         firstAttribute;
@property (nonatomic, assign, readonly) int16_t         secondAttribute;
@property (nonatomic, assign, readonly) int16_t         relation;
@property (nonatomic, assign, readonly) float           multiplier;
@property (nonatomic, assign)           float           constant;
@property (nonatomic, strong, readonly) RemoteElement * firstItem;
@property (nonatomic, strong, readonly) RemoteElement * secondItem;
@property (nonatomic, strong)           RemoteElement * owner;
@property (nonatomic, assign)           float           priority;

@property (nonatomic, weak, readonly)   RemoteElementLayoutConfiguration * configuration;
@property (nonatomic, readonly, getter = isStaticConstraint) BOOL        staticConstraint;

+ (RemoteElementLayoutConstraint *)constraintWithItem:(RemoteElement *)element1
                                            attribute:(NSLayoutAttribute)attr1
                                            relatedBy:(NSLayoutRelation)relation
                                               toItem:(RemoteElement *)element2
                                            attribute:(NSLayoutAttribute)attr2
                                           multiplier:(CGFloat)multiplier
                                             constant:(CGFloat)c;
+ (RemoteElementLayoutConstraint *)constraintWithAttributeValues:(NSDictionary *)attributes;
- (BOOL)hasAttributeValues:(NSDictionary *)values;

- (NSString *)committedValuesDescription;

@end

MSKIT_EXTERN_STRING   RemoteElementModelConstraintNametag;

/*
 * RELayoutConstraint
 */
@interface RELayoutConstraint:NSLayoutConstraint

@property (nonatomic, strong) RemoteElementLayoutConstraint    * modelConstraint;
@property (readonly, weak)    RemoteElementView                * firstItem;
@property (readonly, weak)    RemoteElementView                * secondItem;
@property (nonatomic, weak)   RemoteElementView                * owner;
@property (nonatomic, assign, readonly, getter = isValid) BOOL   valid;
@property (nonatomic, weak, readonly)   NSString               * identifier;

/**
 * Constructor for new `RELayoutConstraint` objects.
 *
 * @param modelConstraint Model to be represented by the `RELayoutConstraint`
 *
 * @param view View to which the constraint will be added
 *
 * @return Newly created constraint for the specified view
 */
+ (RELayoutConstraint *)constraintWithModel:(RemoteElementLayoutConstraint *)modelConstraint
                                    forView:(RemoteElementView *)view;

@end

typedef NS_ENUM (NSUInteger, RELayoutConstraintOrder){
    RELayoutConstraintUnspecifiedOrder = 0,
    RELayoutConstraintFirstOrder       = 1,
    RELayoutConstraintSecondOrder      = 2
};

typedef NS_OPTIONS (NSUInteger, RELayoutConstraintAffiliation){
    RELayoutConstraintUnspecifiedAffiliation    = 0,
    RELayoutConstraintFirstItemAffiliation      = 1 << 0,
    RELayoutConstraintSecondItemAffiliation     = 1 << 1,
    RELayoutConstraintOwnerAffiliation          = 1 << 2
};


