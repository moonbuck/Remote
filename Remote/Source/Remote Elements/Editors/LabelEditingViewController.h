//
// LabelEditingViewController.h
// Remote
//
// Created by Jason Cardwell on 3/29/12.
// Copyright (c) 2012 Moondeer Studios. All rights reserved.
//
@import UIKit;
@import CoreData;
@import Foundation;
#import "Lumberjack/Lumberjack.h"
@import Moonkit;
#import "MSRemoteMacros.h"
#import "ColorSelectionViewController.h"
#import "AttributeEditingViewController.h"

@class   LabelEditingViewController;

@protocol LabelEditingDelegate <NSObject>

- (void)labelEditorCanceled:(LabelEditingViewController *)labelEditor;

- (void)labelEditor:(LabelEditingViewController *)labelEditor
      saveRequested:(NSDictionary *)saveValues;

@end

@interface LabelEditingViewController : AttributeEditingViewController <UIPickerViewDelegate,
                                                                        UIPickerViewDataSource,
                                                                        UITextViewDelegate,
                                                                        UITextFieldDelegate,
                                                                        ColorSelectionDelegate>

@property (nonatomic, weak) id <LabelEditingDelegate>   delegate;

@end
