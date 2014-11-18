//
//  Button.swift
//  Remote
//
//  Created by Jason Cardwell on 11/09/14.
//  Copyright (c) 2014 Moondeer Studios. All rights reserved.
//

import Foundation
import CoreData
import MoonKit

@objc(Button)
class Button: RemoteElement {

  struct State: RawOptionSetType {

    private(set) var rawValue: Int
    init(rawValue: Int) { self.rawValue = rawValue & 0b0111 }
    init(nilLiteral:()) { rawValue = 0 }

    static var Default:     State = State(rawValue: 0b0000)
    static var Normal:      State = State.Default
    static var Highilghted: State = State(rawValue: 0b0001)
    static var Disabled:    State = State(rawValue: 0b0010)
    static var Selected:    State = State(rawValue: 0b0100)

  }

  /**
  elementType

  :returns: BaseType
  */
   override func elementType() -> BaseType { return .Button }

  @NSManaged var title:            NSAttributedString?
  @NSManaged var icon:             ImageView?
  @NSManaged var image:            ImageView?
  @NSManaged var titles:           ControlStateTitleSet?
  @NSManaged var icons:            ControlStateImageSet?
  @NSManaged var backgroundColors: ControlStateColorSet?
  @NSManaged var images:           ControlStateImageSet?
  @NSManaged var command:          Command?
  @NSManaged var longPressCommand: Command?

  @NSManaged var primitiveState: NSNumber
  var state: State {
    get {
      willAccessValueForKey("state")
      let state = primitiveState
      didAccessValueForKey("state")
      return State(rawValue: state.integerValue)
    }
    set {
      willChangeValueForKey("state")
      primitiveState = newValue.rawValue
      didChangeValueForKey("state")
    }
  }

  var selected: Bool {
    get {
      willAccessValueForKey("selected")
      let selected = state & State.Selected != nil
      didAccessValueForKey("selected")
      return selected
    }
    set {
      willChangeValueForKey("selected")
      if newValue { state |= State.Selected } else { state &= ~State.Selected }
      didChangeValueForKey("selected")
    }
  }

  var highlighted: Bool {
    get {
      willAccessValueForKey("highlighted")
      let highlighted = state & State.Highilghted != nil
      didAccessValueForKey("highlighted")
      return highlighted
    }
    set {
      willChangeValueForKey("highlighted")
      if newValue { state |= State.Highilghted } else { state &= ~State.Highilghted }
      didChangeValueForKey("highlighted")
    }
  }

  var enabled: Bool {
    get {
      willAccessValueForKey("enabled")
      let enabled = state & State.Disabled == nil
      didAccessValueForKey("enabled")
      return enabled
    }
    set {
      willChangeValueForKey("enabled")
      if !newValue { state |= State.Disabled } else { state &= ~State.Disabled }
      didChangeValueForKey("enabled")
    }
  }

  @NSManaged var primitiveTitleEdgeInsets: NSValue
  var titleEdgeInsets: UIEdgeInsets {
    get {
      willAccessValueForKey("titleEdgeInsets")
      let insets = primitiveTitleEdgeInsets
      didAccessValueForKey("titleEdgeInsets")
      return insets.UIEdgeInsetsValue()
    }
    set {
      willChangeValueForKey("titleEdgeInsets")
      primitiveTitleEdgeInsets = NSValue(UIEdgeInsets: newValue)
      didChangeValueForKey("titleEdgeInsets")
    }
  }

  @NSManaged var primitiveImageEdgeInsets: NSValue
  var imageEdgeInsets: UIEdgeInsets {
    get {
      willAccessValueForKey("imageEdgeInsets")
      let insets = primitiveImageEdgeInsets
      didAccessValueForKey("imageEdgeInsets")
      return insets.UIEdgeInsetsValue()
    }
    set {
      willChangeValueForKey("imageEdgeInsets")
      primitiveImageEdgeInsets = NSValue(UIEdgeInsets: newValue)
      didChangeValueForKey("imageEdgeInsets")
    }
  }

  @NSManaged var primitiveContentEdgeInsets: NSValue
  var contentEdgeInsets: UIEdgeInsets {
    get {
      willAccessValueForKey("contentEdgeInsets")
      let insets = primitiveContentEdgeInsets
      didAccessValueForKey("contentEdgeInsets")
      return insets.UIEdgeInsetsValue()
    }
    set {
      willChangeValueForKey("contentEdgeInsets")
      primitiveContentEdgeInsets = NSValue(UIEdgeInsets: newValue)
      didChangeValueForKey("contentEdgeInsets")
    }
  }

  /**
   executeCommandWithOptions:

   :param: options CommandOptions
   :param: completion ((Bool, NSError?) -> Void)?
   */
   func executeCommandWithOptions(options: CommandOptions, completion: ((Bool, NSError?) -> Void)?) {
     var c: Command?

     switch options {
       case .Default:   c = command
       case .LongPress: c = longPressCommand
     }

     if c != nil { c!.execute(completion) } else { completion?(true, nil) }
   }

  /**
  setCommand:forMode:

  :param: command Command?
  :param: mode String
  */
  func setCommand(command: Command?, forMode mode: String) {
    setURIForObject(command, forKey: "command", forMode: mode)
  }

  /**
  setLongPressCommand:forMode:

  :param: command Command?
  :param: mode String
  */
  func setLongPressCommand(command: Command?, forMode mode: String) {
    setURIForObject(command, forKey: "longPressCommand", forMode: mode)
  }

  /**
  setTitles:forMode:

  :param: titleSet ControlStateTitleSet?
  :param: mode String
  */
  func setTitles(titleSet: ControlStateTitleSet?, forMode mode: String) {
    setURIForObject(titleSet, forKey: "titles", forMode: mode)
  }

  /**
  setBackgroundColors:forMode:

  :param: colorSet ControlStateColorSet?
  :param: mode String
  */
  func setBackgroundColors(colorSet: ControlStateColorSet?, forMode mode: String) {
    setURIForObject(colorSet, forKey: "backgroundColors", forMode: mode)
  }

  /**
  setIcons:forMode:

  :param: imageSet ControlStateImageSet?
  :param: mode String
  */
  func setIcons(imageSet: ControlStateImageSet?, forMode mode: String) {
    setURIForObject(imageSet, forKey: "icons", forMode: mode)
  }

  /**
  setImages:forMode:

  :param: imageSet ControlStateImageSet?
  :param: mode String
  */
  func setImages(imageSet: ControlStateImageSet?, forMode mode: String) {
    setURIForObject(imageSet, forKey: "images", forMode: mode)
  }

  /**
  commandForMode:

  :param: mode String

  :returns: Command?
  */
  func commandForMode(mode: String) -> Command? {
    return faultedObjectForKey("command", forMode: mode) as? Command
  }

  /**
  longPressCommandForMode:

  :param: mode String

  :returns: Command?
  */
  func longPressCommandForMode(mode: String) -> Command? {
    return faultedObjectForKey("longPressCommand", forMode: mode) as? Command
  }

  /**
  titlesForMode:

  :param: mode String

  :returns: ControlStateTitleSet?
  */
  func titlesForMode(mode: String) -> ControlStateTitleSet? {
    return faultedObjectForKey("titles", forMode: mode) as? ControlStateTitleSet
  }

  /**
  backgroundColorsForMode:

  :param: mode String

  :returns: ControlStateColorSet?
  */
  func backgroundColorsForMode(mode: String) -> ControlStateColorSet? {
    return faultedObjectForKey("backgroundColors", forMode: mode) as? ControlStateColorSet
  }

  /**
  iconsForMode:

  :param: mode String

  :returns: ControlStateImageSet?
  */
  func iconsForMode(mode: String) -> ControlStateImageSet? {
    return faultedObjectForKey("icons", forMode: mode) as? ControlStateImageSet
  }

  /**
  imagesForMode:

  :param: mode String

  :returns: ControlStateImageSet?
  */
  func imagesForMode(mode: String) -> ControlStateImageSet? {
    return faultedObjectForKey("images", forMode: mode) as? ControlStateImageSet
  }

  /** updateButtonForState */
  func updateButtonForState() {
    let idx = UInt(state.rawValue)
    title = titles?[idx] as? NSAttributedString
    icon = icons?[idx] as? ImageView
    image = images?[idx] as? ImageView
    backgroundColor = backgroundColors?[idx] as? UIColor
  }

  /**
  updateForMode:

  :param: mode String
  */
  override func updateForMode(mode: String) {
    super.updateForMode(mode)
    command          = commandForMode(mode)          ?? commandForMode(RemoteElement.DefaultMode)
    longPressCommand = longPressCommandForMode(mode) ?? longPressCommandForMode(RemoteElement.DefaultMode)
    titles           = titlesForMode(mode)           ?? titlesForMode(RemoteElement.DefaultMode)
    icons            = iconsForMode(mode)            ?? iconsForMode(RemoteElement.DefaultMode)
    images           = imagesForMode(mode)           ?? imagesForMode(RemoteElement.DefaultMode)
    backgroundColors = backgroundColorsForMode(mode) ?? backgroundColorsForMode(RemoteElement.DefaultMode)

    updateButtonForState()
  }

  /**
  updateWithData:

  :param: data [NSObject AnyObject]
  */
  override func updateWithData(data: [NSObject:AnyObject]) {
    super.updateWithData(data)

    if let moc = managedObjectContext {

      if let titles = data["titles"] as? [String:[String:AnyObject]] {
        for (mode, values) in titles {
          setTitles(ControlStateTitleSet.importObjectFromData(values, context: moc), forMode: mode)
        }
      }

      if let icons = data["icons"] as? [String:[String:AnyObject]] {
        for (mode, values) in icons {
          setIcons(ControlStateImageSet.importObjectFromData(values, context: moc), forMode: mode)
        }
      }

      if let images = data["images"] as? [String:[String:AnyObject]] {
        for (mode, values) in images {
          setImages(ControlStateImageSet.importObjectFromData(values, context: moc), forMode: mode)
        }
      }

      if let backgroundColors = data["background-colors"] as? [String:[String:AnyObject]] {
        for (mode, values) in backgroundColors {
          setBackgroundColors(ControlStateColorSet.importObjectFromData(values, context: moc), forMode: mode)
        }
      }

      if let commands = data["commands"] as? [String:[String:AnyObject]] {
        for (mode, values) in commands {
          setCommand(Command.importObjectFromData(values, context: moc), forMode: mode)
        }
      }

      if let longPressCommands = data["long-press-commands"] as? [String:[String:AnyObject]] {
        for (mode, values) in longPressCommands {
          setCommand(Command.importObjectFromData(values, context: moc), forMode: mode)
        }
      }

      if let titleEdgeInsets = data["title-edge-insets"] as? String {
        self.titleEdgeInsets = UIEdgeInsetsFromString(titleEdgeInsets)
      }

      if let contentEdgeInsets = data["content-edge-insets"] as? String {
        self.contentEdgeInsets = UIEdgeInsetsFromString(contentEdgeInsets)
      }

      if let imageEdgeInsets = data["image-edge-insets"] as? String {
        self.imageEdgeInsets = UIEdgeInsetsFromString(imageEdgeInsets)
      }

    }

  }

  /**
  JSONDictionary

  :returns: MSDictionary
  */
  override func JSONDictionary() -> MSDictionary {
    let dictionary = super.JSONDictionary()
    dictionary["background-color"] = NSNull()

    func ifNotDefaultSetValue(value: @autoclosure () -> NSObject?, forKey key: String) {
      if let v = value() {
        if !attributeValueIsDefault(key) {
          dictionary[key.camelCaseToDashCase()] = v
        }
      }
    }

    let titles            = MSDictionary()
    let backgroundColors  = MSDictionary()
    let icons             = MSDictionary()
    let images            = MSDictionary()
    let commands          = MSDictionary()
    let longPressCommands = MSDictionary()

    for mode in modes as [String] {
      if let modeTitles = titlesForMode(mode)?.JSONDictionary() { titles[mode] = modeTitles }
      if let modeBackgroundColors = backgroundColorsForMode(mode)?.JSONDictionary() {
        backgroundColors[mode] = modeBackgroundColors
      }
      if let modeIcons = iconsForMode(mode)?.JSONDictionary() { icons[mode] = modeIcons }
      if let modeImages = imagesForMode(mode)?.JSONDictionary() { images[mode] = modeImages }
      if let modeCommand = commandForMode(mode)?.JSONDictionary() { commands[mode] = modeCommand }
      if let modeLongPressCommand = longPressCommandForMode(mode)?.JSONDictionary() {
        longPressCommands[mode] = modeLongPressCommand
      }
    }

    dictionary["commands"]           = commands
    dictionary["titles"]             = titles
    dictionary["icons"]              = icons
    dictionary["background-colors"]  = backgroundColors
    dictionary["images"]             = images

    ifNotDefaultSetValue(NSStringFromUIEdgeInsets(titleEdgeInsets),   forKey: "titleEdgeInsets")
    ifNotDefaultSetValue(NSStringFromUIEdgeInsets(imageEdgeInsets),   forKey: "imageEdgeInsets")
    ifNotDefaultSetValue(NSStringFromUIEdgeInsets(contentEdgeInsets), forKey: "contentEdgeInsets")

    dictionary.compact()
    dictionary.compress()

    return dictionary
  }

  /**
  deepDescriptionDictionary

  :returns: MSDictionary
  */
  override func deepDescriptionDictionary() -> MSDictionary {

    let element = faultedObject()

    let stringFromDescription: (String?) -> String = {
      string in string == nil || string!.isEmpty ? "nil" : string!.stringByShiftingLeft(4)
    }

    let dd = super.deepDescriptionDictionary()

    dd["titles"]            = stringFromDescription(element.titles?.deepDescription())
    dd["icons"]             = stringFromDescription(element.icons?.deepDescription())
    dd["backgroundColors"]  = stringFromDescription(element.backgroundColors?.deepDescription())
    dd["images"]            = stringFromDescription(element.images?.deepDescription())
    dd["command"]           = stringFromDescription(element.command?.deepDescription())
    dd["longPressCommand"]  = stringFromDescription(element.longPressCommand?.deepDescription())
    dd["titleEdgeInsets"]   = "\(element.titleEdgeInsets)"
    dd["imageEdgeInsets"]   = "\(element.imageEdgeInsets)"
    dd["contentEdgeInsets"] = "\(element.contentEdgeInsets)"


    return dd
  }

}

extension Button.State: Equatable {}
func ==(lhs: Button.State, rhs: Button.State) -> Bool { return lhs.rawValue == rhs.rawValue }

extension Button.State: BitwiseOperationsType {
  static var allZeros: Button.State { return self(rawValue: 0) }
}
func &(lhs: Button.State, rhs: Button.State) -> Button.State {
  return Button.State(rawValue: (lhs.rawValue & rhs.rawValue))
}
func |(lhs: Button.State, rhs: Button.State) -> Button.State {
  return Button.State(rawValue: (lhs.rawValue | rhs.rawValue))
}
func ^(lhs: Button.State, rhs: Button.State) -> Button.State {
  return Button.State(rawValue: (lhs.rawValue ^ rhs.rawValue))
}
prefix func ~(x: Button.State) -> Button.State { return Button.State(rawValue: ~(x.rawValue)) }