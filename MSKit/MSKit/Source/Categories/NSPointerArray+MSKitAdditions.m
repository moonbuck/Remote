//
//  NSPointerArray+MSKitAdditions.m
//  MSKit
//
//  Created by Jason Cardwell on 10/21/13.
//  Copyright (c) 2013 Jason Cardwell. All rights reserved.
//

#import "NSPointerArray+MSKitAdditions.h"

@implementation NSPointerArray (MSKitAdditions)

- (id)objectAtIndexedSubscript:(NSUInteger)idx { return [self pointerAtIndex:idx]; }

@end
