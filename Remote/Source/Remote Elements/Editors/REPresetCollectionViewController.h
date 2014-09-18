//
//  REPresetCollectionViewController.h
//  Remote
//
//  Created by Jason Cardwell on 4/2/13.
//  Copyright (c) 2013 Moondeer Studios. All rights reserved.
//
@import UIKit;
@import CoreData;
@import Foundation;
#import "Lumberjack/Lumberjack.h"
@import Moonkit;
#import "MSRemoteMacros.h"

@import UIKit;

@interface REPresetCollectionViewController : UICollectionViewController

+ (REPresetCollectionViewController *)presetControllerWithLayout:(UICollectionViewLayout *)layout;

@property (nonatomic, strong) NSManagedObjectContext * context;

@end
