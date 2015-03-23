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

  struct PanelAssignment: RawOptionSetType, JSONValueConvertible {

    private(set) var rawValue: Int
    init(rawValue: Int) { self.rawValue = rawValue & 0b0001_1111 }
    init(nilLiteral:()) { rawValue = 0 }

    enum Location: Int, JSONValueConvertible {
      case Undefined, Top, Bottom, Left, Right
      var JSONValue: String {
        switch self {
          case .Undefined: return "undefined"
          case .Top:       return "top"
          case .Bottom:    return "bottom"
          case .Left:      return "left"
          case .Right:     return "right"
        }
      }
      init(JSONValue: String) {
        switch JSONValue {
          case "top":    self = .Top
          case "bottom": self = .Bottom
          case "left":   self = .Left
          case "right":  self = .Right
          default:       self = .Undefined
        }
      }
    }
    enum Trigger: Int, JSONValueConvertible  {
      case Undefined, OneFinger, TwoFinger, ThreeFinger
      var JSONValue: String {
        switch self {
          case .Undefined:   return "undefined"
          case .OneFinger:   return "1"
          case .TwoFinger:   return "2"
          case .ThreeFinger: return "3"
        }
      }
     init(JSONValue: String) {
       switch JSONValue {
         case "1": self = .OneFinger
         case "2": self = .TwoFinger
         case "3": self = .ThreeFinger
         default:  self = .Undefined
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

    init(JSONValue: String) {
      rawValue = 0
      let length = count(JSONValue)
      if length > 3 {
        location = Location(JSONValue: String(JSONValue[0 ..< (length - 1)]))
        trigger = Trigger(JSONValue: String(JSONValue[(length - 1) ..< length]))
      }
    }
    var JSONValue: String { return "\(location.JSONValue)\(trigger.JSONValue)"}

  }

  override var elementType: BaseType { return .ButtonGroup }

  /** awakeFromInsert */
  override func awakeFromInsert() {
    super.awakeFromInsert()
    labelAttributes = DictionaryStorage(context: managedObjectContext!)
  }

  /**
  initWithPreset:

  :param: preset Preset
  */
  override init(preset: Preset) {
    super.init(preset: preset)

    autohide = preset.autohide ?? false

    if let labelAttributes = preset.labelAttributes { self.labelAttributes.dictionary = labelAttributes }
    labelConstraints = preset.labelConstraints
    // if let panelAssignment = preset.panelAssignment { self.panelAssignment = panelAssignment }
  }

  required init(context: NSManagedObjectContext, insert: Bool) {
      fatalError("init(context:insert:) has not been implemented")
  }

  required init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
      fatalError("init(entity:insertIntoManagedObjectContext:) has not been implemented")
  }

  required init(context: NSManagedObjectContext?) {
      fatalError("init(context:) has not been implemented")
  }

  required init?(data: [String : AnyObject], context: NSManagedObjectContext) {
      fatalError("init(data:context:) has not been implemented")
  }

  /**
  initWithEntity:insertIntoManagedObjectContext:

  :param: entity NSEntityDescription
  :param: context NSManagedObjectContext?
  */
//  override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
//    super.init(entity: entity, insertIntoManagedObjectContext: context)
//  }

  /**
  initWithContext:

  :param: context NSManagedObjectContext
  */
//  override init(context: NSManagedObjectContext) {
//    super.init(context: context)
//  }

  @NSManaged var commandContainer: CommandContainer?
  @NSManaged var autohide: Bool
  // @NSManaged var label: NSAttributedString?
  @NSManaged var labelAttributes: DictionaryStorage
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
      commandSet = collection.commandSetAtIndex(commandSetIndex)
    }
    commandSet = commandSet?.faultedObject()
    if commandSet != nil {
      for button in childElements.array as! [Button] {
         if button.role == RemoteElement.Role.Tuck { continue }
         button.command = commandSet![button.role]
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
        if let text = collection.labelAtIndex(idx) {
          if let storage = labelAttributes.dictionary as? [String:AnyObject] {
            var titleAttributes = TitleAttributes(storage: storage)
            titleAttributes.text = text
            commandSetLabel = titleAttributes.string
          }
        }
      }
    }
    return commandSetLabel
  }

  /**
  updateWithData:

  :param: data [String:AnyObject]
  */
  override func updateWithData(data: [String:AnyObject]) {
    super.updateWithData(data)

    if let moc = managedObjectContext {

      if let autohide = data["autohide"] as? NSNumber { self.autohide = autohide.boolValue }

      if let commandSetData = data["command-set"] as? [String:[String:AnyObject]] {
        for (mode, values) in commandSetData {
          setCommandContainer(CommandSet.importObjectWithData(values, context: moc), forMode: mode)
        }
      }

      else if let collectionData = data["command-set-collection"] as? [String:[String:AnyObject]] {
        for (mode, values) in collectionData {
          setCommandContainer(CommandSetCollection.importObjectWithData(values, context: moc), forMode: mode)
        }
      }

      labelConstraints = data["label-constraints"] as? String

      if let labelAttributesData = data["label-attributes"] as? [String:AnyObject] {
        labelAttributes.dictionary = labelAttributesData
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
    if !labelAttributes.dictionary.isEmpty { dictionary["label-attributes"] = labelAttributes.dictionary }

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
