//
//  MoonKit_Tests.m
//  MoonKit Tests
//
//  Created by Jason Cardwell on 9/17/14.
//  Copyright (c) 2014 Jason Cardwell. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
@import MoonKit;

static int ddLogLevel   = LOG_LEVEL_DEBUG;
static int msLogContext = LOG_CONTEXT_CONSOLE;
#pragma unused(ddLogLevel,msLogContext)

@interface MoonKit_Tests : XCTestCase

@end

@implementation MoonKit_Tests

+ (void)initialize { if (self == [MoonKit_Tests class]) [MSLog addTaggingTTYLogger]; }

- (void)testJSONParser {

  NSString * filePath = [[NSBundle bundleWithPath:UserDefaults[@"XCTestedBundlePath"]] pathForResource:@"test"
                                                                                                ofType:@"json"];
  NSError * error = nil;
  NSString * json = [NSString stringWithContentsOfFile:filePath encoding:NSUTF8StringEncoding error:&error];
  MSLogDebug(@"test json input:\n%@\n", json);

  if (MSHandleErrors(error)) XCTFail("error encountered creating json string from testfile");
  error = nil;

  id object = [JSONSerialization objectByParsingString:json options:1 error:&error];
  if (MSHandleErrors(error)) XCTFail("error encountered creating json object from string using `JSONSerialization`");
  XCTAssert(object != nil);
  MSLogDebug(@"json from parsed object:\n%@\n", [JSONSerialization JSONFromObject:object options:0]);

}

@end