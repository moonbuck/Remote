//
// IconSelectionViewController.h
// Remote
//
// Created by Jason Cardwell on 3/31/12.
// Copyright (c) 2012 Moondeer Studios. All rights reserved.
//

@class   IconSelectionViewController, REIconImage;

@protocol IconSelectionDelegate <NSObject>

- (void)iconSelector:(IconSelectionViewController *)controller didSelectIcon:(REIconImage *)icon;

- (void)iconSelectorDidCancel:(IconSelectionViewController *)controller;

@end

#import "SelectionTableViewController.h"

@interface IconSelectionViewController : SelectionTableViewController <UIGestureRecognizerDelegate>

@property (nonatomic, weak) id <IconSelectionDelegate>   delegate;
@property (nonatomic, strong) NSManagedObjectContext   * context;

@end
