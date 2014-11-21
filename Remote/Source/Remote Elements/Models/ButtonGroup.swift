//
//  ButtonGroup.swift
//  Remote
//
//  Created by Jason Cardwell on 11/11/14.
//  Copyright (c) 2014 Moondeer Studios. All rights reserved.
//

import Foundation
import CoreData
import MoonKit

/**
`ButtonGroup` is an `NSManagedObject` subclass that models a group of buttons for a home
theater remote control. Its main function is to manage a collection of <Button> objects and to
interact with the <Remote> object to which it typically will belong. <ButtonGroupView> objects
use an instance of the `ButtonGroup` class to govern their style, behavior, etc.
*/
@objc(ButtonGroup)
class ButtonGroup: RemoteElement {

  struct PanelAssignment: RawOptionSetType {

    private(set) var rawValue: Int
    init(rawValue: Int) { self.rawValue = rawValue & 0b0001_1111 }
    init(nilLiteral:()) { rawValue = 0 }

    enum Location: Int {
      case Undefined, Top, Bottom, Left, Right
      var JSONKey: String {
        switch self {
          case .Undefined: return "undefined"
          case .Top: return "top"
          case .Bottom: return "bottom"
          case .Left: return "left"
          case .Right: return "right"
        }
      }
    }
    enum Trigger: Int  {
      case Undefined, OneFinger, TwoFinger, ThreeFinger
      var JSONKey: String {
        switch self {
          case .Undefined: return "undefined"
          case .OneFinger: return "1"
          case .TwoFinger: return "2"
          case .ThreeFinger: return "3"
        }
      }
    }

    var location: Location {
      get { return Location(rawValue: rawValue & 0b0111) ?? .Undefined }
      set { rawValue = newValue.rawValue | (trigger.rawValue >> 3) }
    }
    var trigger: Trigger {
      get { return Trigger(rawValue: (rawValue << 3) & 0b0011) ?? .Undefined }
      set { rawValue = location.rawValue | (newValue.rawValue >> 3) }
    }

    /**
    initWithLocation:trigger:

    :param: location Location
    :param: trigger Trigger
    */
    init(location: Location, trigger: Trigger) { rawValue = location.rawValue | (trigger.rawValue >> 3) }

    static var Unassigned: PanelAssignment = PanelAssignment(location: .Undefined, trigger: .Undefined)

    var JSONKey: String { return "\(location.JSONKey)\(trigger.JSONKey)"}

  }

  override var elementType: BaseType { return .ButtonGroup }

  @NSManaged var commandContainer: CommandContainer?
  @NSManaged var autohide: Bool
  // @NSManaged var label: NSAttributedString?
  @NSManaged var labelAttributes: TitleAttributes?
  @NSManaged var labelConstraints: String?

  var isPanel: Bool { return panelLocation != .Undefined && panelTrigger != .Undefined }

  var panelLocation: PanelAssignment.Location {
    get { return panelAssignment.location }
    set { var assignment = panelAssignment; assignment.location = newValue; panelAssignment = assignment }
  }

  var panelTrigger: PanelAssignment.Trigger {
    get { return panelAssignment.trigger }
    set { var assignment = panelAssignment; assignment.trigger = newValue; panelAssignment = assignment }
  }

  @NSManaged var primitivePanelAssignment: NSNumber
  var panelAssignment: PanelAssignment {
    get {
      willAccessValueForKey("panelAssignment")
      let panelAssignment = PanelAssignment(rawValue: primitivePanelAssignment.integerValue)
      didAccessValueForKey("panelAssignment")
      return panelAssignment
    }
    set {
      willChangeValueForKey("panelAssignment")
      primitivePanelAssignment = newValue.rawValue
      didChangeValueForKey("panelAssignment")
    }
  }

  /**
  setCommandContainer:forMode:

  :param: container CommandContainer?
  :param: mode String
  */
  func setCommandContainer(container: CommandContainer?, forMode mode: String) {
    setURIForObject(container, forKey: "commandContainer", forMode: mode)
  }

  /**
  commandContainerForMode:

  :param: mode String

  :returns: CommandContainer?
  */
  func commandContainerForMode(mode: String) -> CommandContainer? {
    return faultedObjectForKey("commandContainer", forMode: mode) as? CommandContainer
  }

  /**
  setLabel:forMode:

  :param: label NSAttributedString?
  :param: mode String
  */
  func setLabel(label: NSAttributedString?, forMode mode: String) {
    setObject(label, forKey: "label", forMode: mode)
  }

  /**
  labelForMode:

  :param: mode String

  :returns: NSAttributedString?
  */
  func labelForMode(mode: String) -> NSAttributedString? {
    return objectForKey("label", forMode: mode) as? NSAttributedString
  }

    /**
  updateForMode:

  :param: mode String
  */
  override func updateForMode(mode: String) {
    super.updateForMode(mode)
    commandContainer = commandContainerForMode(mode) ?? commandContainerForMode(RemoteElement.DefaultMode)

    updateButtons()
  }

  var commandSetIndex: Int = 0 {
    didSet {
      if let collection = commandContainer as? CommandSetCollection {
        if !contains((0 ..< Int(collection.count)), commandSetIndex) { commandSetIndex = 0 }
        updateButtons()
      }
    }
  }

  /** updateButtons */
  func updateButtons() {
    var commandSet: CommandSet?
    if commandContainer != nil && commandContainer! is CommandSet { commandSet = commandContainer! as? CommandSet }
    else if let collection = commandContainer as? CommandSetCollection {
      commandSet = collection.commandSetAtIndex(UInt(commandSetIndex))
    }
    commandSet = commandSet?.faultedObject()
    if commandSet != nil {
      for button in childElements.array as [Button] {
         if button.role == RemoteElement.Role.Tuck { continue }
         button.command = commandSet![button.role.rawValue]
         button.enabled = button.command != nil
      }
    }
  }

  /**
  labelForCommandSetAtIndex:

  :param: idx Int

  :returns: NSAttributedString?
  */
  func labelForCommandSetAtIndex(idx: Int) -> NSAttributedString? {
    var commandSetLabel: NSAttributedString?
    if let collection = commandContainer as? CommandSetCollection {
      if contains(0 ..< Int(collection.count), idx) {
        if let text = collection.labelAtIndex(UInt(idx)) {
          labelAttributes?.text = text
          commandSetLabel = labelAttributes?.string ?? NSAttributedString(string: text)
        }
      }
    }
    return commandSetLabel
  }

  /**
  updateWithData:

  :param: data [NSObject AnyObject]
  */
  override func updateWithData(data: [NSObject:AnyObject]) {
    super.updateWithData(data)

    if let moc = managedObjectContext {

      if let autohide = data["autohide"] as? NSNumber { self.autohide = autohide.boolValue }

      if let commandSetData = data["command-set"] as? [String:[String:AnyObject]] {
        for (mode, values) in commandSetData {
          setCommandContainer(CommandSet.importObjectFromData(values, context: moc), forMode: mode)
        }
      }

      else if let collectionData = data["command-set-collection"] as? [String:[String:AnyObject]] {
        for (mode, values) in collectionData {
          setCommandContainer(CommandSetCollection.importObjectFromData(values, context: moc), forMode: mode)
        }
      }

      labelConstraints = data["label-constraints"] as? String

      if let labelAttributesData = data["label-attributes"] as? [String:[String:AnyObject]] {
        labelAttributes = TitleAttributes.importObjectFromData(labelAttributesData, context: moc)
      }

    }

  }

  /**
  JSONDictionary

  :returns: MSDictionary
  */
  override func JSONDictionary() -> MSDictionary {
    let dictionary = super.JSONDictionary()

    let commandSets = MSDictionary()
    let commandSetCollections = MSDictionary()
    let labels = MSDictionary()

    for mode in modes as [String] {
      if let container = commandContainerForMode(mode) {
        let dict = container.JSONDictionary()
        if container is CommandSetCollection { commandSetCollections[mode] = dict }
        else if container is CommandSet { commandSets[mode] = dict }
      }
      if let label = labelForMode(mode) { labels[mode] = label }
    }

    if commandSetCollections.count > 0 { dictionary["command-set-collection"] = commandSetCollections }
    if commandSets.count > 0 { dictionary["command-set"] = commandSets }
    if labels.count > 0 { dictionary["label"] = labels }
    if let constraints = labelConstraints { dictionary["label-constraints"] = constraints }
    if let attributes = labelAttributes { dictionary["label-attributes"] = attributes.JSONDictionary() }

    dictionary.compact()
    dictionary.compress()

    return dictionary
  }

}

extension ButtonGroup.PanelAssignment: Equatable {}
func ==(lhs: ButtonGroup.PanelAssignment, rhs: ButtonGroup.PanelAssignment) -> Bool { return lhs.rawValue == rhs.rawValue }

extension ButtonGroup.PanelAssignment: BitwiseOperationsType {
  static var allZeros: ButtonGroup.PanelAssignment { return self(rawValue: 0) }
}
func &(lhs: ButtonGroup.PanelAssignment, rhs: ButtonGroup.PanelAssignment) -> ButtonGroup.PanelAssignment {
  return ButtonGroup.PanelAssignment(rawValue: (lhs.rawValue & rhs.rawValue))
}
func |(lhs: ButtonGroup.PanelAssignment, rhs: ButtonGroup.PanelAssignment) -> ButtonGroup.PanelAssignment {
  return ButtonGroup.PanelAssignment(rawValue: (lhs.rawValue | rhs.rawValue))
}
func ^(lhs: ButtonGroup.PanelAssignment, rhs: ButtonGroup.PanelAssignment) -> ButtonGroup.PanelAssignment {
  return ButtonGroup.PanelAssignment(rawValue: (lhs.rawValue ^ rhs.rawValue))
}
prefix func ~(x: ButtonGroup.PanelAssignment) -> ButtonGroup.PanelAssignment {
  return ButtonGroup.PanelAssignment(rawValue: ~(x.rawValue))
}
