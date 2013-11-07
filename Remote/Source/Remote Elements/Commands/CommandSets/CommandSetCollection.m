//
// CommandSetCollection.m
// Remote
//
// Created by Jason Cardwell on 6/29/11.
// Copyright (c) 2011 Moondeer Studios. All rights reserved.
//
#import "CommandSetCollection.h"
#import "CommandSet.h"
#import "CommandContainer_Private.h"

static int ddLogLevel = LOG_LEVEL_DEBUG;
static int msLogContext = LOG_CONTEXT_CONSOLE;
#pragma unused(ddLogLevel,msLogContext)

@implementation CommandSetCollection

@dynamic commandSets;


/// Assigning a `CommandSet` to a label
- (void)setObject:(CommandSet *)commandSet forKeyedSubscript:(NSString *)label
{
    if (!commandSet) ThrowInvalidNilArgument(commandSet);
    else if (!label) ThrowInvalidNilArgument(label);

    else
    {
        [self addCommandSetsObject:commandSet];
        _index[label] = commandSet.uuid;
    }
}

/// Retrieving the label for a `CommandSet`
- (NSString *)labelForCommandSet:(CommandSet *)commandSet
{
    return [_index keyForObject:commandSet.uuid];
}

/// Retrieving the `CommandSet` for a label
- (CommandSet *)objectForKeyedSubscript:(NSString *)label
{
    if (!label) ThrowInvalidNilArgument(label);

    return [CommandSet objectWithUUID:_index[label] context:self.managedObjectContext];
}

- (void)insertCommandSet:(CommandSet *)commandSet forLabel:(NSString *)label atIndex:(NSUInteger)index
{
    if (!commandSet) ThrowInvalidNilArgument(commandSet);
    else if (!label) ThrowInvalidNilArgument(label);
    else if (index >= self.count) ThrowInvalidIndexArgument(index);
    else
    {
        [self insertObject:commandSet inCommandSetsAtIndex:index];
        [_index insertObject:commandSet.uuid forKey:label atIndex:index];
    }
}

- (CommandSet *)commandSetAtIndex:(NSUInteger)idx
{
    NSOrderedSet * commandSets = self.commandSets;
    if ([commandSets count] <= idx) ThrowInvalidIndexArgument(idx);
    
    return commandSets[idx];
}

- (NSString *)labelAtIndex:(NSUInteger)index
{
    if (index >= self.count) ThrowInvalidIndexArgument(index);
    else
        return [_index keyAtIndex:index];
}

- (NSArray *)labels { return [_index allKeys]; }

- (NSUInteger)countByEnumeratingWithState:(NSFastEnumerationState *)state
                                  objects:(__unsafe_unretained id *)stackbuf
                                    count:(NSUInteger)len
{
    return [_index countByEnumeratingWithState:state objects:stackbuf count:len];
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark Import and export
////////////////////////////////////////////////////////////////////////////////

+ (id)MR_importFromObject:(id)data inContext:(NSManagedObjectContext *)context
{
    if (!context) ThrowInvalidNilArgument(context);
    else if (!isDictionaryKind(data)) ThrowInvalidArgument(data, "must be some kind of dictionary");

    CommandSetCollection * collection = [self commandContainerInContext:context];
    assert(collection.count == 0);

    for (NSString * label in data)
    {
        if (!isStringKind(label)) continue;

        CommandSet * commandSet = [CommandSet MR_importFromObject:data[label] inContext:context];

        if (commandSet) collection[label] = commandSet;
    }

    return collection;
}

- (MSDictionary *)JSONDictionary
{
    MSDictionary * dictionary = [super JSONDictionary];
    [dictionary removeObjectForKey:@"uuid"];

    for (NSString * label in _index)
    {
        CommandSet * commandSet = self[label];
        if (commandSet) dictionary[label] = CollectionSafe(commandSet.JSONDictionary);
    }

    [dictionary compact];
    [dictionary compress];
    
    return dictionary;
}


@end



////////////////////////////////////////////////////////////////////////////////
#pragma mark Accessors
////////////////////////////////////////////////////////////////////////////////


@interface CommandSetCollection (CoreDataGeneratedAccessors)

@property (nonatomic, strong) NSMutableOrderedSet * primitiveCommandSets;

@end


@implementation CommandSetCollection (CommandSetAccessors)

MSSTATIC_STRING_CONST kCommandSetsKey = @"commandSets";

- (void)insertObject:(CommandSet *)value inCommandSetsAtIndex:(NSUInteger)index
{
    NSIndexSet * indexes = [NSIndexSet indexSetWithIndex:index];
    [self willChange:NSKeyValueChangeInsertion valuesAtIndexes:indexes forKey:kCommandSetsKey];
    [self.primitiveCommandSets insertObject:value atIndex:index];
    [self didChange:NSKeyValueChangeInsertion valuesAtIndexes:indexes forKey:kCommandSetsKey];
}

- (void)removeObjectFromCommandSetsAtIndex:(NSUInteger)index
{
    NSIndexSet * indexes = [NSIndexSet indexSetWithIndex:index];
    [self willChange:NSKeyValueChangeRemoval valuesAtIndexes:indexes forKey:kCommandSetsKey];
    [self.primitiveCommandSets removeObjectAtIndex:index];
    [self didChange:NSKeyValueChangeRemoval valuesAtIndexes:indexes forKey:kCommandSetsKey];
}

- (void)insertCommandSets:(NSArray *)values atIndexes:(NSIndexSet *)indexes
{
    [self willChange:NSKeyValueChangeInsertion valuesAtIndexes:indexes forKey:kCommandSetsKey];
    [self.primitiveCommandSets insertObjects:values atIndexes:indexes];
    [self didChange:NSKeyValueChangeInsertion valuesAtIndexes:indexes forKey:kCommandSetsKey];
}

- (void)removeCommandSetsAtIndexes:(NSIndexSet *)indexes
{
    [self willChange:NSKeyValueChangeRemoval valuesAtIndexes:indexes forKey:kCommandSetsKey];
    [self.primitiveCommandSets removeObjectsAtIndexes:indexes];
    [self didChange:NSKeyValueChangeRemoval valuesAtIndexes:indexes forKey:kCommandSetsKey];
}

- (void)replaceObjectInCommandSetsAtIndex:(NSUInteger)index withObject:(CommandSet *)value
{
    NSIndexSet * indexes = [NSIndexSet indexSetWithIndex:index];
    [self willChange:NSKeyValueChangeReplacement valuesAtIndexes:indexes forKey:kCommandSetsKey];
    self.primitiveCommandSets[index] = value;
    [self didChange:NSKeyValueChangeReplacement valuesAtIndexes:indexes forKey:kCommandSetsKey];
}

- (void)replaceCommandSetsAtIndexes:(NSIndexSet *)indexes withCommandSets:(NSArray *)values
{
    [self willChange:NSKeyValueChangeReplacement valuesAtIndexes:indexes forKey:kCommandSetsKey];
    [self.primitiveCommandSets replaceObjectsAtIndexes:indexes withObjects:values];
    [self didChange:NSKeyValueChangeReplacement valuesAtIndexes:indexes forKey:kCommandSetsKey];
}

- (void)addCommandSetsObject:(CommandSet *)value
{
    NSIndexSet * indexes = [NSIndexSet indexSetWithIndex:[self.primitiveCommandSets count]];
    [self willChange:NSKeyValueChangeInsertion valuesAtIndexes:indexes forKey:kCommandSetsKey];
    [self.primitiveCommandSets addObject:value];
    [self didChange:NSKeyValueChangeInsertion valuesAtIndexes:indexes forKey:kCommandSetsKey];
}

- (void)removeCommandSetsObject:(CommandSet *)value
{
    NSUInteger   index = [self.primitiveCommandSets indexOfObject:value];
    if (index != NSNotFound) {
        NSIndexSet * indexes = [NSIndexSet indexSetWithIndex:index];
        [self willChange:NSKeyValueChangeRemoval valuesAtIndexes:indexes forKey:kCommandSetsKey];
        [self.primitiveCommandSets removeObject:value];
        [self didChange:NSKeyValueChangeRemoval valuesAtIndexes:indexes forKey:kCommandSetsKey];
    }
}

- (void)addCommandSets:(NSOrderedSet *)values
{
    if ([values count]) {
        NSIndexSet * indexes = [NSIndexSet indexSetWithIndexesInRange:
                                NSMakeRange([self.primitiveCommandSets count], [values count])];
        [self willChange:NSKeyValueChangeInsertion valuesAtIndexes:indexes forKey:kCommandSetsKey];
        [self.primitiveCommandSets addObjectsFromArray:[values array]];
        [self didChange:NSKeyValueChangeInsertion valuesAtIndexes:indexes forKey:kCommandSetsKey];
    }
}

- (void)removeCommandSets:(NSOrderedSet *)values
{
    NSIndexSet * indexes = [self.primitiveCommandSets
                            indexesOfObjectsPassingTest:
                            ^BOOL(id obj, NSUInteger index, BOOL *stop)
                            {
                                return YES;
                            }];

    if ([indexes count]) {
        [self willChange:NSKeyValueChangeRemoval valuesAtIndexes:indexes forKey:kCommandSetsKey];
        [self.primitiveCommandSets removeObjectsAtIndexes:indexes];
        [self didChange:NSKeyValueChangeRemoval valuesAtIndexes:indexes forKey:kCommandSetsKey];
    }
}

@end