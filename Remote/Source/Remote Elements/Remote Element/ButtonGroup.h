//
// RemoteElement.h
// Remote
//
// Created by Jason Cardwell on 10/3/12.
// Copyright © 2012 Moondeer Studios. All rights reserved.
//
#import "RemoteElement.h"

@class CommandContainer, CommandSetCollection, CommandSet, Button;

/**
* `ButtonGroup` is an `NSManagedObject` subclass that models a group of buttons for a home
* theater remote control. Its main function is to manage a collection of <Button> objects and to
* interact with the <Remote> object to which it typically will belong. <ButtonGroupView> objects
* use an instance of the `ButtonGroup` class to govern their style, behavior, etc.
*/
@interface ButtonGroup : RemoteElement

+ (instancetype)buttonGroupWithRole:(RERole)role;
+ (instancetype)buttonGroupWithRole:(RERole)role context:(NSManagedObjectContext *)moc;


/**
* Retrieve a Button object contained by the `ButtonGroup` by its key.
* @param key The key for the Button object.
* @return The Button specified or nil if it does not exist.
*/
- (Button *)objectForKeyedSubscript:(NSString *)subscript;
- (Button *)objectAtIndexedSubscript:(NSUInteger)subscript;

- (void)addCommandContainer:(CommandContainer *)container mode:(RERemoteMode)mode;

/**
 * Add a new `CommandSet` for the specified label text.
 * @param commandSet The `CommandSet` object to add the `PickerLabelButtonGroup`'s collection.
 * @param label The display name for selecting the `CommandSet`.
 */
- (void)addCommandSet:(CommandSet *)commandSet withLabel:(id)label;

/**
* Label text for the optional `UILabelView`.
*/
@property (nonatomic, copy) NSAttributedString * label;

/**
* String used to generate auto layout  constraint for the label.
*/
@property (nonatomic, copy) NSString * labelConstraints;

/**
* REPanelLocation referring to which side the `ButtonGroup` appears when attached to a
* Remote as a panel.
*/
@property (nonatomic, assign) REPanelLocation panelLocation;
@property (nonatomic, assign) REPanelTrigger panelTrigger;
@property (nonatomic, assign) REPanelAssignment panelAssignment;

@property (nonatomic, strong, readonly) Remote * parentElement;
@property (nonatomic, weak, readonly) ButtonGroupConfigurationDelegate * groupConfigurationDelegate;

- (BOOL)isPanel;
- (void)setCommandContainer:(CommandContainer *)container;

@property (nonatomic, readonly) CommandSetCollection * commandSetCollection;

@end

MSEXTERN_NAMETAG(REButtonGroupPanel);