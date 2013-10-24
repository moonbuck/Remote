//
//  MSGestureManager.m
//  MSKit
//
//  Created by Jason Cardwell on 2/22/13.
//  Copyright (c) 2013 Moondeer Studios. All rights reserved.
//

#import "MSGestureManager.h"
#import "NSNull+MSKitAdditions.h"
#import "NSArray+MSKitAdditions.h"

@implementation MSGestureManager {
    NSMapTable          * _gestureMap;
}

+ (MSGestureManager *)gestureManagerForGestures:(NSArray *)gestures
{
    return [self gestureManagerForGestures:gestures blocks:nil];
}

+ (MSGestureManager *)gestureManagerForGestures:(NSArray *)gestures blocks:(NSArray *)blocks
{

    MSGestureManager * manager = [MSGestureManager new];

    [gestures enumerateObjectsUsingBlock:^(UIGestureRecognizer * obj, NSUInteger idx, BOOL *stop) {
        [manager addGesture:obj withBlocks:blocks[idx]];
    }];

    return manager;

}

- (id)init
{
    if (self = [super init])
    {
        _gestureMap = [NSMapTable weakToStrongObjectsMapTable];
    }

    return self;
}

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer
{
    MSGestureManagerBlock block =
        [_gestureMap objectForKey:gestureRecognizer][@(MSGestureManagerResponseTypeBegin)];

    BOOL answer = (block ? block(gestureRecognizer,nil) : YES);

    return answer;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch
{
    MSGestureManagerBlock block =
    [_gestureMap objectForKey:gestureRecognizer][@(MSGestureManagerResponseTypeReceiveTouch)];
    BOOL answer = (block ? block(gestureRecognizer,touch) : YES);
    return answer;
}

- (BOOL)                             gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer
    shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
    MSGestureManagerBlock block =
    [_gestureMap objectForKey:gestureRecognizer][@(MSGestureManagerResponseTypeRecognizeSimultaneously)];
    BOOL answer = (block ? block(gestureRecognizer,otherGestureRecognizer) : NO);
    return answer;
}

- (void)addGesture:(UIGestureRecognizer *)gesture
{
    [self  addGesture:gesture withBlocks:nil];
}

- (void)addGesture:(UIGestureRecognizer *)gesture withBlocks:(NSDictionary *)blocks
{
    NSMutableDictionary * responseBlocks = [@{} mutableCopy];
    if (blocks)
        [responseBlocks addEntriesFromDictionary:blocks];
    
    [_gestureMap setObject:responseBlocks forKey:gesture];
}

- (void)removeGesture:(UIGestureRecognizer *)gesture
{
    [_gestureMap removeObjectForKey:gesture];
}

- (void)registerBlock:(MSGestureManagerBlock)block
          forResponse:(MSGestureManagerResponseType)response
           forGesture:(UIGestureRecognizer *)gesture
{
    if (block)
        [[_gestureMap objectForKey:gesture] setObject:block forKey:@(response)];
    else
        [[_gestureMap objectForKey:gesture] removeObjectForKey:@(response)];
}

@end