//
//  ComponentDevice.swift
//  Remote
//
//  Created by Jason Cardwell on 9/30/14.
//  Copyright (c) 2014 Moondeer Studios. All rights reserved.
//

import Foundation
import CoreData
import MoonKit

@objc(ComponentDevice)
class ComponentDevice: BankableModelObject {

  @NSManaged var alwaysOn: Bool
  @NSManaged var inputPowersOn: Bool
  @NSManaged var port: Int16
  @NSManaged var power: Bool
  @NSManaged var codes: NSSet
  @NSManaged var manufacturer: Manufacturer?
  @NSManaged var networkDevice: NetworkDevice?
  @NSManaged var offCommand: Command?
  @NSManaged var onCommand: Command?
  @NSManaged var powerCommands: NSSet

  private var ignoreNextPowerCommand = false

  func ignorePowerCommand(completion: ((Bool, NSError?) -> Void)?) -> Bool {
    if ignoreNextPowerCommand {
      ignoreNextPowerCommand = false
      completion?(true, nil)
      return true
    } else { return false }
  }


  func powerOn(completion: ((Bool, NSError?) -> Void)?) {
    if !ignorePowerCommand(completion) {
      offCommand?.execute{[unowned self] (success: Bool, error: NSError?) in
        if success { self.power = true }
        completion?(success, error)
      }
    }
  }

  func powerOff(completion: ((Bool, NSError?) -> Void)?) {
    if !ignorePowerCommand(completion) {
      offCommand?.execute{[unowned self] (success: Bool, error: NSError?) in
        if success { self.power = false }
        completion?(success, error)
      }
    }
  }

  /**
  objectForKeyedSubscript:

  :param: name String!

  :returns: AnyObject!
  */
  override func objectForKeyedSubscript(name: String!) -> AnyObject! {
    return (codes.allObjects as [IRCode]).filter{$0.name == name}.first
  }

  /**
  updateWithData:

  :param: data [NSObject AnyObject]!
  */
  override func updateWithData(data: [NSObject : AnyObject]!) {
    super.updateWithData(data)

    port = (data["port"] as? NSNumber)?.shortValue
      ?? port
    onCommand = Command.importObjectFromData(data["on-command"] as? NSDictionary, context: managedObjectContext)
      ?? onCommand
    offCommand = Command.importObjectFromData(data["off-command"] as? NSDictionary, context: managedObjectContext)
      ?? offCommand
    manufacturer = Manufacturer.importObjectFromData(data["manufacturer"] as? NSDictionary, context: managedObjectContext)
      ?? manufacturer
    networkDevice = NetworkDevice.importObjectFromData(data["network-device"] as? NSDictionary, context: managedObjectContext)
      ?? networkDevice

    if let newCodes = IRCode.importObjectsFromData(data["codes"], context: managedObjectContext) {
      let mutableCodes: NSMutableSet = mutableSetValueForKey("codes") ?? NSMutableSet()
      mutableCodes.addObjectsFromArray(newCodes)
    }
  }

}

extension ComponentDevice: MSJSONExport {

  override func JSONDictionary() -> MSDictionary! {

    let dictionary = super.JSONDictionary()

    setIfNotDefault("port",          inDictionary: dictionary)
    setIfNotDefault("alwaysOn",      inDictionary: dictionary)
    setIfNotDefault("inputPowersOn", inDictionary: dictionary)
      
    safeSetValueForKeyPath("onCommand.JSONDictionary",    forKey: "on-command",          inDictionary: dictionary)
    safeSetValueForKeyPath("offCommand.JSONDictionary",   forKey: "off-command",         inDictionary: dictionary)
    safeSetValueForKeyPath("manufacturer.commentedUUID",  forKey: "manufacturer.uuid",   inDictionary: dictionary)
    safeSetValueForKeyPath("networkDevice.commentedUUID", forKey: "network-device.uuid", inDictionary: dictionary)
    safeSetValueForKeyPath("codes.JSONDictionary",        forKey: "codes",               inDictionary: dictionary)

    dictionary.compact()
    dictionary.compress()

    return dictionary

  }

}

extension ComponentDevice: BankDisplayItem {

  class var label: String   { return "Component Devices"              }
  class var icon:  UIImage? { return UIImage(named: "969-television") }

  class var isThumbnailable: Bool { return false }
  class var isDetailable:    Bool { return true  }
  class var isEditable:      Bool { return true  }
  class var isPreviewable:   Bool { return false }

}

extension ComponentDevice: BankDisplayItemModel {

  var detailController: BankDetailController { return ComponentDeviceDetailController(item: self, editing: false) }

}