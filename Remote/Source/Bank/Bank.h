//
//  Bank.h
//  Remote
//
//  Created by Jason Cardwell on 9/13/13.
//  Copyright (c) 2013 Moondeer Studios. All rights reserved.
//
@import UIKit;
@import CoreData;
@import Foundation;
#import "Lumberjack/Lumberjack.h"
@import MoonKit;
#import "MSRemoteMacros.h"
#import "NamedModelObject.h"

@class BankableModelObject, BankItemViewController;


/** Protocol to ensure all bank objects have the necessary info to display */

@protocol BankableModel <NamedModel>

/// directoryLabel
/// @return NSString *
+ (NSString *)directoryLabel;

/// isThumbnailable
/// @return BOOL
+ (BOOL)isThumbnailable;

/// isPreviewable
/// @return BOOL
+ (BOOL)isPreviewable;

/// isDetailable
/// @return BOOL
+ (BOOL)isDetailable;

/// isEditable
/// @return BOOL
+ (BOOL)isEditable;

/// isSectionable
/// @return BOOL
+ (BOOL)isSectionable;

/// directoryIcon
/// @return UIImage *
+ (UIImage *)directoryIcon;

/// detailViewControllerClass
/// @return BankItemViewController *
- (BankItemViewController *)detailViewController;

/// editingViewController
/// @return BankItemViewController *
- (BankItemViewController *)editingViewController;

/// allItems
/// @return NSFetchedResultsController *
+ (NSFetchedResultsController *)allItems;

/// updateItem
- (void)updateItem;

/// resetItem
- (void)resetItem;

@property (nonatomic, copy)                          NSString     * name;
@property (nonatomic, copy)                          NSString     * category;
@property (nonatomic, readonly)                      UIImage      * thumbnail;
@property (nonatomic, readonly)                      UIImage      * preview;
@property (nonatomic, copy)                          NSNumber     * user;
@property (nonatomic, readonly, getter = isEditable) BOOL           editable;
@property (nonatomic, readonly)                      MSDictionary * subitems;

@end

/** The bank singleton interface */

@interface Bank : MSSingletonController

/// registeredClasses
/// @return NSArray *
+ (NSArray *)registeredClasses;

@end

