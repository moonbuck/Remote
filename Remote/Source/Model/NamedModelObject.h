//
//  NamedModelObject.h
//  Remote
//
//  Created by Jason Cardwell on 11/3/13.
//  Copyright (c) 2013 Moondeer Studios. All rights reserved.
//
@import UIKit;
@import CoreData;
@import Foundation;
#import "Lumberjack/Lumberjack.h"
#import "MSKit/MSKit.h"
#import "MSRemoteMacros.h"

#import "ModelObject.h"

@interface NamedModelObject : ModelObject <NamedModel>

@property (nonatomic, readonly) NSString * commentedUUID;
@property (nonatomic, strong) NSString * name;
@property (nonatomic, assign) BOOL isNameAutoGenerated;

@end
