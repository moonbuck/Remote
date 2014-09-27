//
//  RemoteElementImportSupportFunctions.h
//  Remote
//
//  Created by Jason Cardwell on 4/30/13.
//  Copyright (c) 2013 Moondeer Studios. All rights reserved.
//
@import UIKit;
@import CoreData;
@import Foundation;
@import Lumberjack;
@import MoonKit;
#import "MSRemoteMacros.h"
#import "RETypedefs.h"

////////////////////////////////////////////////////////////////////////////////
#pragma mark - Remote Element Types
////////////////////////////////////////////////////////////////////////////////

Class remoteElementClassForImportKey(NSString * importKey);
REType remoteElementTypeFromImportKey(NSString * importKey);
RERole remoteElementRoleFromImportKey(NSString * importKey);

////////////////////////////////////////////////////////////////////////////////
#pragma mark - Remote Element State
////////////////////////////////////////////////////////////////////////////////

REState   buttonStateFromImportKey(NSString * importKey);

////////////////////////////////////////////////////////////////////////////////
#pragma mark - Remote Element Shape & Style
////////////////////////////////////////////////////////////////////////////////

REShape remoteElementShapeFromImportKey(NSString * importKey);
REStyle remoteElementStyleFromImportKey(NSString * importKey);
REThemeOverrideFlags remoteElementThemeFlagsFromImportKey(NSString * importKey);

////////////////////////////////////////////////////////////////////////////////
#pragma mark - Remote
////////////////////////////////////////////////////////////////////////////////

REPanelAssignment panelAssignmentFromImportKey(NSString * importKey);

////////////////////////////////////////////////////////////////////////////////
#pragma mark - Commands
////////////////////////////////////////////////////////////////////////////////

SystemCommandType systemCommandTypeFromImportKey(NSString * importKey);
SwitchCommandType switchCommandTypeFromImportKey(NSString * importKey);
CommandSetType commandSetTypeFromImportKey(NSString * importKey);
Class commandClassForImportKey(NSString * importKey);

////////////////////////////////////////////////////////////////////////////////
#pragma mark Control state sets
////////////////////////////////////////////////////////////////////////////////

NSString * titleAttributesPropertyForJSONKey(NSString * key);
NSString * titleSetAttributeKeyForJSONKey(NSString * key);
NSTextAlignment textAlignmentForJSONKey(NSString * key);
NSLineBreakMode lineBreakModeForJSONKey(NSString * key);
NSUnderlineStyle underlineStrikethroughStyleForJSONKey(NSString * key);

////////////////////////////////////////////////////////////////////////////////
#pragma mark - Utility functions
////////////////////////////////////////////////////////////////////////////////

UIColor * colorFromImportValue(NSString * importValue);
