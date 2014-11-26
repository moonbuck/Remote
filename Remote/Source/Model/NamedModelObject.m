//
//  NamedModelObject.m
//  Remote
//
//  Created by Jason Cardwell on 11/3/13.
//  Copyright (c) 2013 Moondeer Studios. All rights reserved.
//

#import "NamedModelObject.h"

@interface NamedModelObject (CoreDataGenerated)
@property (nonatomic) NSString * primitiveName;
@end

@implementation NamedModelObject

@dynamic name, isNameAutoGenerated;

+ (BOOL)requiresUniqueNaming { return NO; }

+ (BOOL)objectExistsWithName:(NSString *)name {
  return StringIsNotEmpty(name) && [self countOfObjectsWithPredicate:NSPredicateMake(@"name == %@", name)] > 0;
}

- (void)willSave {
  if (!self.isDeleted && StringIsEmpty(self.primitiveName)) { [self autoGenerateName]; }
}

//- (void)awakeFromInsert {
//  [super awakeFromInsert];
//  [self autoGenerateName];
//}

- (void)autoGenerateName {
  [self.managedObjectContext processPendingChanges];
  
  NSString * base = self.className;
  NSPredicate * predicate = NSPredicateMake(@"name like %@", $(@"%@*", base));
  NSUInteger count = [[self class] countOfObjectsWithPredicate:predicate context:self.managedObjectContext] + 1;
  NSString * generatedName = $(@"%@%lu", base, (unsigned long)count);
  while ([[self class] objectExistsWithName:generatedName]) generatedName = $(@"%@%lu", base, (unsigned long)count);
  self.primitiveName = generatedName;
  self.isNameAutoGenerated = YES;
}

- (NSString *)name {
  [self willAccessValueForKey:@"name"];
  NSString * n = self.primitiveName;
  if (StringIsEmpty(n)) {
    [self autoGenerateName];
    n = self.primitiveName;
  }
  [self didAccessValueForKey:@"name"];
  return n;
}

- (void)setName:(NSString *)name {
  if ([[self class] requiresUniqueNaming] && [[self class] objectExistsWithName:name]) return;
  [self willChangeValueForKey:@"name"];
  self.primitiveName = name;
  [self didChangeValueForKey:@"name"];
  if (name) self.isNameAutoGenerated = NO;
  else [self autoGenerateName];
}

- (void)updateWithData:(NSDictionary *)data {
  [super updateWithData:data];
  self.name = data[@"name"] ?: self.name;
}

- (MSDictionary *)JSONDictionary {
  MSDictionary * dictionary = [super JSONDictionary];
  if (!self.isNameAutoGenerated)
    SafeSetValueForKey(self.name, @"name", dictionary);
  return dictionary;
}

- (NSString *)commentedUUID {
  NSString * uuid = self.uuid;

  if (uuid) {
    NSString * name = self.name;

    if (name) uuid.comment = MSSingleLineComment(name);
  }

  return uuid;
}

@end
