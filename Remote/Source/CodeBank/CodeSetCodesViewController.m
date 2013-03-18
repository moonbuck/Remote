//
// CodeSetCodesViewController.m
// Remote
//
// Created by Jason Cardwell on 3/22/12.
// Copyright (c) 2012 Moondeer Studios. All rights reserved.
//
#import "CodeSetCodesViewController.h"
#import "IRCodeSet.h"
#import "IRCode.h"
#import "IRCodeDetailViewController.h"

static int   ddLogLevel = DefaultDDLogLevel;

#pragma unused(ddLogLevel)

@interface CodeSetCodesViewController ()

@property (nonatomic, strong) NSArray * fetchedCodes;

@end

@implementation CodeSetCodesViewController

@synthesize codeSet, fetchedCodes;

- (void)viewDidLoad {
    [super viewDidLoad];
    if (ValueIsNotNil(self.codeSet)) self.navigationItem.title = self.codeSet.name;
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.fetchedCodes count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString * CellIdentifier = @"Cell";
    UITableViewCell * cell           = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];

    // Configure the cell...
    IRCode * code = self.fetchedCodes[indexPath.row];

    cell.textLabel.text = code.name;

    return cell;
}

- (void)setCodeSet:(IRCodeSet *)newCodeSet {
    codeSet           = newCodeSet;
    self.fetchedCodes =
        [[codeSet.codes allObjects]
         sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"name"
                                                                     ascending:YES]]];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if (  [@"Push Code Detail" isEqualToString : segue.identifier]
       && [segue.destinationViewController isMemberOfClass:[IRCodeDetailViewController class]])
        [(IRCodeDetailViewController *)segue.destinationViewController
         setCode : self.fetchedCodes[
                                     [self.tableView indexPathForSelectedRow].row]];
}

@end
