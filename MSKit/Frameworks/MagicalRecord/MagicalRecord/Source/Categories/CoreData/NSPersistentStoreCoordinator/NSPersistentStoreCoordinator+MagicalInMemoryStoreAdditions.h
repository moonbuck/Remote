//
//  NSPersistentStoreCoordinator+MagicalInMemoryStoreAdditions.h
//  MagicalRecord
//
//  Created by Saul Mora on 9/14/13.
//  Copyright (c) 2013 Magical Panda Software LLC. All rights reserved.
//

#import <CoreData/CoreData.h>

@interface NSPersistentStoreCoordinator (MagicalInMemoryStoreAdditions)

+ (NSPersistentStoreCoordinator *) MR_coordinatorWithInMemoryStore;

- (NSPersistentStore *) MR_addInMemoryStore;

@end
