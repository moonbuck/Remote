//
//  PresetAttributes.swift
//  Remote
//
//  Created by Jason Cardwell on 11/21/14.
//  Copyright (c) 2014 Moondeer Studios. All rights reserved.
//

import Foundation
import UIKit
import MoonKit

public final class PresetAttributes {

  // private var storage: [String:AnyObject]
  // var dictionaryValue: NSDictionary { return storage as NSDictionary }

  private let storage: DictionaryStorage
  public var dictionaryValue: NSDictionary { return storage.dictionary }

  public let context: NSManagedObjectContext?

  /**
  initWithStorage:

  :param: storage [String String]
  */
  // init(storage: [String:AnyObject], context: NSManagedObjectContext?) { self.storage = storage; self.context = context }


  public init(storage: DictionaryStorage) { self.storage = storage; self.context = storage.managedObjectContext }

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
      if let moc = context, path = storage["backgroundImage"] as? String {
        return Image.objectWithIndex(PathIndex(path)!, context: moc)
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

  public var subelements: [PresetAttributes]? {
    get { return nil } // return (storage["subelements"] as? [[String:AnyObject]])?.map{PresetAttributes(storage: $0, context: self.context)} }
    set { } //storage["subelements"] = newValue?.map{$0.storage} }
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

  public var label: NSAttributedString? {
    get { return storage["label"] as? NSAttributedString }
    set { storage["label"] = newValue }
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

  public var titleEdgeInsets: UIEdgeInsets? {
    get { return (storage["title-edge-insets"] as? NSValue)?.UIEdgeInsetsValue() }
    set { storage["title-edge-insets"] = newValue == nil ? nil : NSValue(UIEdgeInsets: newValue!) }
  }

  public var contentEdgeInsets: UIEdgeInsets? {
    get { return (storage["content-edge-insets"] as? NSValue)?.UIEdgeInsetsValue() }
    set { storage["contentEdgeInsets"] = newValue == nil ? nil : NSValue(UIEdgeInsets: newValue!) }
  }

  public var imageEdgeInsets: UIEdgeInsets? {
    get { return (storage["image-edge-insets"] as? NSValue)?.UIEdgeInsetsValue() }
    set { storage["image-edge-insets"] = newValue == nil ? nil : NSValue(UIEdgeInsets: newValue!) }
  }

  public var command: [String:String]? {
    get { return storage["command"] as? [String:String] }
    set { storage["command"] = newValue }
  }

}
