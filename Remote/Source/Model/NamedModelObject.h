//
//  NamedModelObject.h
//  Remote
//
//  Created by Jason Cardwell on 11/3/13.
//  Copyright (c) 2013 Moondeer Studios. All rights reserved.
//

#import "ModelObject.h"

@interface NamedModelObject : ModelObject <NamedModelObject>

@property (nonatomic, readonly) NSString * commentedUUID;
@property (nonatomic, strong, readwrite) NSString * name;

@end
