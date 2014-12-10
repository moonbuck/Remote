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
class Preset: BankableModelObject, PreviewableItem {

  @NSManaged var presetCategory: PresetCategory?

  var preview: UIImage { return UIImage() }
  var thumbnail: UIImage { return preview }

  @NSManaged var storage: DictionaryStorage

  /** awakeFromInsert */
  override func awakeFromInsert() {
    super.awakeFromInsert()
    storage = DictionaryStorage(context: managedObjectContext!)
  }

  /**
  detailController

  :returns: UIViewController
  */
  override func detailController() -> UIViewController {
    switch baseType {
      case .Remote:      return RemotePresetDetailController(model: self)
      case .ButtonGroup: return ButtonGroupPresetDetailController(model: self)
      case .Button:      return ButtonPresetDetailController(model: self)
      case .Undefined:   return PresetDetailController(model: self)
    }
  }

  class var rootCategory: Bank.RootCategory {
    var categories = PresetCategory.findAllMatchingPredicate(∀"parentCategory == nil") as [PresetCategory]
    categories.sort{$0.0.title < $0.1.title}
    return Bank.RootCategory(label: "Presets",
                             icon: UIImage(named: "1059-sliders")!,
                             subcategories: categories,
                             editableItems: true,
                             previewableItems: true)
  }

  subscript(key: String) -> AnyObject? {
    get { return storage[key] }
    set { storage[key] = newValue }
  }

  /**
  generateElement

  :returns: RemoteElement?
  */
  func generateElement() -> RemoteElement? {
    return managedObjectContext != nil
             ? RemoteElement.remoteElementFromPreset(self, context: managedObjectContext!)
             : nil
  }

  /**
  updateWithData:

  :param: data [NSObject AnyObject]!
  */
  override func updateWithData(data: [NSObject:AnyObject]) {
    super.updateWithData(data)
    if let jsonData = data as? [String:AnyObject] { storage.dictionary = jsonData }
  }

  /**
  JSONDictionary

  :returns: MSDictionary
  */
  override func JSONDictionary() -> MSDictionary {
    let dictionary = super.JSONDictionary()
    safeSetValueForKeyPath("presetCategory.commentedUUID", forKey: "category", inDictionary: dictionary)
    dictionary.setValuesForKeysWithDictionary(storage.dictionary)
    return dictionary
  }

  var baseType: RemoteElement.BaseType {
    get { return RemoteElement.BaseType(JSONValue: storage["base-type"] as? String ?? "undefined") }
    set { storage["base-type"] = newValue.JSONValue }
  }

  var role: RemoteElement.Role {
    get { return RemoteElement.Role(JSONValue: storage["role"] as? String ?? "undefined") }
    set { storage["role"] = newValue.JSONValue }
  }

  var shape: RemoteElement.Shape {
    get { return RemoteElement.Shape(JSONValue: storage["shape"] as? String ?? "undefined") }
    set { storage["shape"] = newValue.JSONValue }
  }

  var style: RemoteElement.Style {
    get { return RemoteElement.Style(JSONValue: storage["style"] as? String ?? "undefined") }
    set { storage["style"] = newValue.JSONValue }
  }

  var backgroundImage: Image? {
    get { return ImageCategory.imageForPath(storage["backgroundImage"] as? String, context: managedObjectContext) }
    set { storage["background-image"] = newValue }
  }

  var backgroundImageAlpha: NSNumber? {
    get { return storage["background-image-alpha"] as? NSNumber }
    set { storage["background-image-alpha"] = newValue }
  }

  var backgroundColor: UIColor? {
    get { return UIColor(JSONValue: storage["background-color"] as? String ?? "") }
    set { storage["background-color"] = newValue?.JSONValue }
  }

  var subelements: [PresetAttributes]? {
    get { return nil } // return (storage["subelements"] as? [[String:AnyObject]])?.map{PresetAttributes(storage: $0, context: self.context)} }
    set { } //storage["subelements"] = newValue?.map{$0.storage} }
  }

  var constraints: String? {
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


  var topBarHidden: Bool? {
    get { return (storage["top-bar-hidden"] as? NSNumber)?.boolValue }
    set { storage["top-bar-hidden"] = newValue }
  }

  // panels?


  /// MARK: - ButtonGroup attributes
  ////////////////////////////////////////////////////////////////////////////////


  var autohide: Bool? {
    get { return (storage["autohide"] as? NSNumber)?.boolValue }
    set { storage["autohide"] = newValue }
  }

  var label: NSAttributedString? {
    get { return storage["label"] as? NSAttributedString }
    set { storage["label"] = newValue }
  }

  var labelAttributes: [String:AnyObject]? {
    get { return storage["label-attributes"] as? [String:AnyObject] }
    set { storage["label-attributes"] = newValue }
  }

  var labelConstraints: String? {
    get { return storage["label-constraints"] as? String }
    set { storage["label-constraints"] = newValue }
  }

  var panelAssignment: ButtonGroup.PanelAssignment? {
    get { return ButtonGroup.PanelAssignment(JSONValue: storage["panel-assignment"] as? String ?? "") }
    set { storage["panel-assignment"] = newValue?.JSONValue }
  }

  /// MARK: - Button attributes
  ////////////////////////////////////////////////////////////////////////////////


  /** titles data stored in format ["state":["attribute":"value"]] */
  var titles: [String:[String:AnyObject]]? {
    get { return storage["titles"] as? [String:[String:AnyObject]] }
    set { storage["titles"] = newValue }
  }

  /** icons data stored in format ["state":["image/color":"value"]] */
  var icons: [String:[String:AnyObject]]? {
    get { return storage["icons"] as? [String:[String:AnyObject]] }
    set { storage["icons"] = newValue }
  }

  /** images data stored in format ["state":["image/color":"value"]] */
  var images: [String:[String:AnyObject]]? {
    get { return storage["images"] as? [String:[String:AnyObject]] }
    set { storage["images"] = newValue }
  }

  /** backgroundColors data stored in format ["state":"color"] */
  var backgroundColors: [String:AnyObject]? {
    get { return storage["background-colors"] as? [String:AnyObject] }
    set { storage["background-colors"] = newValue }
  }

  var titleEdgeInsets: UIEdgeInsets? {
    get { return (storage["title-edge-insets"] as? NSValue)?.UIEdgeInsetsValue() }
    set { storage["title-edge-insets"] = newValue == nil ? nil : NSValue(UIEdgeInsets: newValue!) }
  }

  var contentEdgeInsets: UIEdgeInsets? {
    get { return (storage["content-edge-insets"] as? NSValue)?.UIEdgeInsetsValue() }
    set { storage["contentEdgeInsets"] = newValue == nil ? nil : NSValue(UIEdgeInsets: newValue!) }
  }

  var imageEdgeInsets: UIEdgeInsets? {
    get { return (storage["image-edge-insets"] as? NSValue)?.UIEdgeInsetsValue() }
    set { storage["image-edge-insets"] = newValue == nil ? nil : NSValue(UIEdgeInsets: newValue!) }
  }

  var command: [String:String]? {
    get { return storage["command"] as? [String:String] }
    set { storage["command"] = newValue }
  }

}
