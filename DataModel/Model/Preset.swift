//
//  Preset.swift
//  Remote
//
//  Created by Jason Cardwell on 9/30/14.
//  Copyright (c) 2014 Moondeer Studios. All rights reserved.
//

import Foundation
import CoreData
import MoonKit

@objc(Preset)
final public class Preset: EditableModelObject {

  public var preview: UIImage { return UIImage() }
  public var thumbnail: UIImage { return preview }

  @NSManaged public var storage: DictionaryStorage
  @NSManaged public var presetCategory: PresetCategory
  @NSManaged public var subelements: NSOrderedSet?
  @NSManaged public var parentPreset: Preset?

  /** awakeFromInsert */
  override public func awakeFromInsert() {
    super.awakeFromInsert()
    storage = DictionaryStorage(context: managedObjectContext!)
  }

  public subscript(key: String) -> AnyObject? {
    get { return storage[key] }
    set { storage[key] = newValue }
  }

  /**
  updateWithData:

  :param: data [String:AnyObject]
  */
  override public func updateWithData(data: [String:AnyObject]) {
    super.updateWithData(data)
    updateRelationshipFromData(data, forKey: "subelements")
    storage.dictionary = data - "subelements"
  }

  /**
  JSONDictionary

  :returns: MSDictionary
  */
  override public func JSONDictionary() -> MSDictionary {
    let dictionary = super.JSONDictionary()
    appendValueForKeyPath("presetCategory.index", forKey: "preset-category.index", toDictionary: dictionary)
    dictionary.setValuesForKeysWithDictionary(storage.dictionary)
    return dictionary
  }

  public var baseType: RemoteElement.BaseType {
    get { return RemoteElement.BaseType(JSONValue: storage["base-type"] as? String ?? "undefined") }
    set { storage["base-type"] = newValue.JSONValue }
  }

  public var role: RemoteElement.Role {
    get { return RemoteElement.Role(JSONValue: storage["role"] as? String ?? "undefined") }
    set { storage["role"] = newValue.JSONValue }
  }

  public var shape: RemoteElement.Shape {
    get { return RemoteElement.Shape(JSONValue: storage["shape"] as? String ?? "undefined") }
    set { storage["shape"] = newValue.JSONValue }
  }

  public var style: RemoteElement.Style {
    get { return RemoteElement.Style(JSONValue: storage["style"] as? String ?? "undefined") }
    set { storage["style"] = newValue.JSONValue }
  }

  public var backgroundImage: Image? {
    get {
      if let moc = managedObjectContext, index = storage["backgroundImage"] as? String {
        return Image.modelWithIndex(PathIndex(index)!, context: moc)
      } else { return nil }
    }
    set { storage["background-image"] = newValue }
  }

  public var backgroundImageAlpha: NSNumber? {
    get { return storage["background-image-alpha"] as? NSNumber }
    set { storage["background-image-alpha"] = newValue }
  }

  public var backgroundColor: UIColor? {
    get { return UIColor(JSONValue: storage["background-color"] as? String ?? "") }
    set { storage["background-color"] = newValue?.JSONValue }
  }

  public var constraints: String? {
    get {
      if let constraintsArray = storage["constraints"] as? [String] {
        return "\n".join(constraintsArray)
      } else {
        return storage["constraints"] as? String
      }
    }
    set { storage["constraints"] = newValue }
  }

  /// MARK: - Remote attributes
  ////////////////////////////////////////////////////////////////////////////////


  public var topBarHidden: Bool? {
    get { return (storage["top-bar-hidden"] as? NSNumber)?.boolValue }
    set { storage["top-bar-hidden"] = newValue }
  }

  // panels?


  /// MARK: - ButtonGroup attributes
  ////////////////////////////////////////////////////////////////////////////////


  public var autohide: Bool? {
    get { return (storage["autohide"] as? NSNumber)?.boolValue }
    set { storage["autohide"] = newValue }
  }

  public var labelAttributes: [String:AnyObject]? {
    get { return storage["label-attributes"] as? [String:AnyObject] }
    set { storage["label-attributes"] = newValue }
  }

  public var labelConstraints: String? {
    get { return storage["label-constraints"] as? String }
    set { storage["label-constraints"] = newValue }
  }

  public var panelAssignment: ButtonGroup.PanelAssignment? {
    get { return ButtonGroup.PanelAssignment(JSONValue: storage["panel-assignment"] as? String ?? "") }
    set { storage["panel-assignment"] = newValue?.JSONValue }
  }

  /// MARK: - Button attributes
  ////////////////////////////////////////////////////////////////////////////////


  /** titles data stored in format ["state":["attribute":"value"]] */
  public var titles: [String:[String:AnyObject]]? {
    get { return storage["titles"] as? [String:[String:AnyObject]] }
    set { storage["titles"] = newValue }
  }

  /** icons data stored in format ["state":["image/color":"value"]] */
  public var icons: [String:[String:AnyObject]]? {
    get { return storage["icons"] as? [String:[String:AnyObject]] }
    set { storage["icons"] = newValue }
  }

  /** images data stored in format ["state":["image/color":"value"]] */
  public var images: [String:[String:AnyObject]]? {
    get { return storage["images"] as? [String:[String:AnyObject]] }
    set { storage["images"] = newValue }
  }

  /** backgroundColors data stored in format ["state":"color"] */
  public var backgroundColors: [String:AnyObject]? {
    get { return storage["background-colors"] as? [String:AnyObject] }
    set { storage["background-colors"] = newValue }
  }

  public var titleEdgeInsets: UIEdgeInsets {
    get { return UIEdgeInsetsFromString(storage["title-edge-insets"] as? String ?? "{0, 0, 0, 0}") }
    set { storage["title-edge-insets"] = NSStringFromUIEdgeInsets(newValue) }
  }

  public var contentEdgeInsets: UIEdgeInsets {
    get { return UIEdgeInsetsFromString(storage["content-edge-insets"] as? String ?? "{0, 0, 0, 0}") }
    set { storage["contentEdgeInsets"] = NSStringFromUIEdgeInsets(newValue) }
  }

  public var imageEdgeInsets: UIEdgeInsets {
    get { return UIEdgeInsetsFromString(storage["image-edge-insets"] as? String ?? "{0, 0, 0, 0}") }
    set { storage["image-edge-insets"] = NSStringFromUIEdgeInsets(newValue) }
  }

  public var command: [String:String]? {
    get { return storage["command"] as? [String:String] }
    set { storage["command"] = newValue }
  }

  /**
  objectWithIndex:context:

  :param: index PathIndex
  :param: context NSManagedObjectContext

  :returns: Image?
  */
  @objc(objectWithPathIndex:context:)
  public override class func objectWithIndex(index: PathIndex, context: NSManagedObjectContext) -> Preset? {
    if let object = modelWithIndex(index, context: context) {
      MSLogDebug("located preset with name '\(object.name)'")
      return object
    } else { return nil }
  }

  override public var description: String {
    return "\(super.description)\n\t" + "\n\t".join(
      "category = \(presetCategory.index.rawValue)",
      "parent = \(parentPreset?.index.rawValue ?? nil)",
      "base type = \(baseType)",
      "role = \(role)",
      "shape = \(shape)",
      "style = \(style)",
      "background image = \(backgroundImage?.index ?? nil)",
      "background image alpha = \(backgroundImageAlpha?.floatValue ?? nil)",
      "background color = \(backgroundColor ?? nil)",
      "constraints = \(constraints ?? nil)",
      {
        switch self.baseType {
        case .Remote:
          return "top bar hidden = \(self.topBarHidden)"
        case .ButtonGroup:
          let labelAttributesString: String
          if let labelAttributes = self.labelAttributes {
            labelAttributesString = "\n" + labelAttributes.description.indentedBy(4)
          } else {
            labelAttributesString = "nil"
          }
          let labelConstraintsString: String
          if let labelConstraints = self.labelConstraints {
            labelConstraintsString = "\n" + labelConstraints.indentedBy(4)
          } else {
            labelConstraintsString = "nil"
          }
          return "\n\t".join(
            "autohide = \(self.autohide ?? nil)",
            "panel assignment = \(self.panelAssignment)",
            "label attributes = \(labelAttributesString)",
            "label constraints = \(labelConstraintsString)"
          )
        case .Button:
          let titlesString: String
          if let titles = self.titles {
            titlesString = "\n" + titles.description.indentedBy(4)
          } else { titlesString = "nil" }
          let iconsString: String
          if let icons = self.icons {
            iconsString = "\n" + icons.description.indentedBy(4)
          } else { iconsString = "nil" }
          let imagesString: String
          if let images = self.images {
            imagesString = "\n" + images.description.indentedBy(4)
          } else { imagesString = "nil" }
          let backgroundColorsString: String
          if let backgroundColors = self.backgroundColors {
            backgroundColorsString = "\n" + backgroundColors.description.indentedBy(4)
          } else { backgroundColorsString = "nil" }

          return "\n\t".join(
            "title edge insets = \(self.titleEdgeInsets)",
            "content edge insets = \(self.contentEdgeInsets)",
            "image edge insets = \(self.imageEdgeInsets)",
            "titles = \(titlesString)",
            "icons = \(iconsString)",
            "images = \(imagesString)",
            "background colors = \(backgroundColorsString)"
          )
        default: break
        }
        return ""
      }()
    )
  }

}

extension Preset: PathIndexedModel {
  public var pathIndex: PathIndex { return presetCategory.pathIndex + indexedName }

  /**
  modelWithIndex:context:

  :param: index PathIndex
  :param: context NSManagedObjectContext

  :returns: Preset?
  */
  public static func modelWithIndex(index: PathIndex, context: NSManagedObjectContext) -> Preset? {
    if index.count < 1 { return nil }
    let presetName = index.removeLast()
    if let presetCategory = PresetCategory.modelWithIndex(index, context: context) {
      return findFirst(presetCategory.presets, {$0.name == presetName})
    } else { return nil }

  }
}