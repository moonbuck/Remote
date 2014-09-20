//
//  BankCollectionViewController.h
//  Remote
//
//  Created by Jason Cardwell on 9/18/13.
//  Copyright (c) 2013 Moondeer Studios. All rights reserved.
//
@import UIKit;
@import CoreData;
@import Foundation;
#import "Lumberjack/Lumberjack.h"
@import MoonKit;
#import "MSRemoteMacros.h"

#import "Bank.h"

@class BankCollectionViewCell;

@interface BankCollectionViewController : UICollectionViewController

/// controllerWithItemClass:
/// @param itemClass
/// @return instancetype
+ (instancetype)controllerWithItemClass:(Class<BankableModel>)itemClass;

@property (nonatomic, strong) Class<BankableModel> itemClass;
@property (nonatomic, strong) NSFetchedResultsController * allItems;

- (void)zoomItem:(BankableModelObject *)item;
- (void)previewItem:(BankableModelObject *)item;
- (void)editItem:(BankableModelObject *)item;
- (void)detailItem:(BankableModelObject *)item;
- (void)deleteItem:(BankableModelObject *)item;
- (void)toggleItemsForSection:(NSInteger)section;

@end
