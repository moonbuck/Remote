//
// RemoteElementConstraintManager.h
// Remote
//
// Created by Jason Cardwell on 2/9/13.
// Copyright (c) 2013 Moondeer Studios. All rights reserved.
//
#import "RETypedefs.h"
#import "REConstraint.h"


RELayoutConstraintAffiliation
remoteElementAffiliationWithConstraint(RemoteElement                 * element,
                                       REConstraint * constraint);

NSString *NSStringFromRELayoutConstraintAffiliation(RELayoutConstraintAffiliation affiliation);
#define RELayoutConstraintAffiliationString(v) NSStringFromRELayoutConstraintAffiliation(v)

RERelationshipType
remoteElementRelationshipTypeForConstraint(RemoteElement                 * element,
                                           REConstraint * constraint);

NSString *NSStringFromRERelationshipType(RERelationshipType relationship);
#define RERelationshipTypeString(v) NSStringFromRERelationshipType(v)

///
UILayoutConstraintAxis UILayoutConstraintAxisForAttribute(NSLayoutAttribute attribute);

MSKIT_EXTERN_STRING   REConstraintsDidChangeNotification;

@class   RemoteElement, REConstraint;

/*
 * RemoteElementConstraintManager
 */
@interface REConstraintManager : NSObject

@property (nonatomic, weak,   readonly) RemoteElement * remoteElement;

@property (nonatomic, assign, getter = shouldShrinkWrap) BOOL shrinkWrap;

/**
 * Creates a new `RemoteElementConstraintManager` to manage `REConstraint` objects
 * for the specified `RemoteElement`.
 *
 * @param remoteElement The element whose constraints need managing
 *
 * @return A fresh manager for the `element`
 */
+ (REConstraintManager *)constraintManagerForRemoteElement:(RemoteElement *)remoteElement;

/**
 * Creates and adds new `REConstraint` objects for the managed element.
 *
 * @param constraints Extended visual format string from which the constraints should be parsed.
 */
- (void)setConstraintsFromString:(NSString *)constraints;

- (void)freezeSize:(CGSize)size
     forSubelement:(RemoteElement *)subelement
         attribute:(NSLayoutAttribute)attribute;

/**
 * Modifies constraints such that any sibling co-dependencies are converted to parent-dependencies.
 * To be frozen, the `firstAttribute` of a constraint must be included in the set of `attributes`.
 *
 * @param constraints Constraints to freeze
 *
 * @param attributes `NSSet` of `NSLayoutAttributes` used to filter whether a constraint is frozen
 *
 * @param metrics Dictionary of element frames keyed by their `identifier` property
 */
- (void)freezeConstraints:(NSSet *)constraints
            forAttributes:(NSSet *)attributes
                  metrics:(NSDictionary *)metrics;

- (void)resizeSubelements:(NSSet *)subelements
                toSibling:(RemoteElement *)sibling
                attribute:(NSLayoutAttribute)attribute
                  metrics:(NSDictionary *)metrics;

- (void)resizeElement:(RemoteElement *)element
             fromSize:(CGSize)currentSize
               toSize:(CGSize)newSize
              metrics:(NSDictionary *)metrics;

- (void)alignSubelements:(NSSet *)subelements
               toSibling:(RemoteElement *)sibling
               attribute:(NSLayoutAttribute)attribute
                 metrics:(NSDictionary *)metrics;

- (void)shrinkWrapSubelements:(NSDictionary *)metrics;

/**
 * Translates the specified subelements by the specified amount.
 *
 * @param subelements s to be translated
 *
 * @param translation Amount by which s will be translated
 *
 * @param metrics Dictionary of element frames keyed by their `identifier` property
 */
- (void)translateSubelements:(NSSet *)subelements
                 translation:(CGPoint)translation
                     metrics:(NSDictionary *)metrics;

- (void)removeMultipliers:(NSDictionary *)metrics;

/**
 * Modifies the constraints of an element such that width and height are not co-dependent.
 *
 * @param element The element whose constraints should be altered
 *
 * @param currentSize The size to use when calculating static width and height
 */
- (void)removeProportionLockForElement:(RemoteElement *)element currentSize:(CGSize)currentSize;

/**
 * Modifies `remoteElement` constraints to avoid unsatisfiable conditions when adding the
 * specified constraint.
 *
 * @param constraint `REConstraint` whose addition may require conflict resolution
 *
 * @param metrics Dictionary of element frames keyed by their `identifier` property
 */
- (void)resolveConflictsForConstraint:(REConstraint *)constraint
                              metrics:(NSDictionary *)metrics;

@end
