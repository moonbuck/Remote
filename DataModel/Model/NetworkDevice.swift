//
//  NetworkDevice.swift
//  Remote
//
//  Created by Jason Cardwell on 9/30/14.
//  Copyright (c) 2014 Moondeer Studios. All rights reserved.
//

import Foundation
import CoreData
import MoonKit

@objc(NetworkDevice)
public class NetworkDevice: EditableModelObject {

  @NSManaged public var uniqueIdentifier: String!
  @NSManaged public var componentDevices: Set<ComponentDevice>

  /**
  deviceExistsWithIdentifier:

  :param: identifier String

  :returns: Bool
  */
  public class func deviceExistsWithIdentifier(identifier: String) -> Bool {
    return objectWithValue(identifier, forAttribute: "uniqueIdentifier", context: DataManager.rootContext) != nil
  }

  override public func updateWithData(data: ObjectJSONValue) {
    super.updateWithData(data)
    if let uniqueIdentifier = String(data["unique-identifier"]) { self.uniqueIdentifier = uniqueIdentifier }
  }

  override public var description: String {
    return "\(super.description)\n\t" + "\n\t".join(
      "unique identifier = \(uniqueIdentifier)",
      "component devices = [" + ", ".join(map(componentDevices, {$0.name})) + "]"
    )
  }

  /**
  importObjectWithData:context:

  :param: data ObjectJSONValue
  :param: context NSManagedObjectContext

  :returns: NetworkDevice?
  */
//  override class func importObjectWithData(data: [String:AnyObject], context: NSManagedObjectContext) -> NetworkDevice? {
//
//    var device: NetworkDevice?
//
//    // Try getting the type of device to import
//    if let type = data["type"] as? String {
//
//      var entityName: String?
//      var deviceType: NetworkDevice.Type = NetworkDevice.self
//
//      // Import with parameters derived from specified type
//      switch type {
//        case "itach":
//          device = importObjectForEntity("ITachDevice", forType: ITachDevice.self, fromData: data, context: context) as? NetworkDevice
//        case "isy":
//          device = importObjectForEntity("ISYDevice", forType: ISYDevice.self, fromData: data, context: context) as? NetworkDevice
//        default:
//          break
//      }
//    }
//
//    return device
//  }

  override public var jsonValue: JSONValue {
    var dict = super.jsonValue.value as! JSONValue.ObjectValue
      dict["unique-identifier"] = JSONValue(uniqueIdentifier)
      return .Object(dict)
  }

}
