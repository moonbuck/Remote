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
class NetworkDevice: BankableModelObject {

  @NSManaged var uniqueIdentifier: String!
  @NSManaged var componentDevices: NSSet?

  class func deviceExistsWithIdentifier(identifier: String) -> Bool {
    return countOfObjectsMatchingPredicate(∀"uniqueIdentifier == \"\(identifier)\"", context: DataManager.rootContext) > 0
  }

  override func updateWithData(data: [String:AnyObject]) {
    super.updateWithData(data)
    uniqueIdentifier = data["unique-identifier"] as? String ?? uniqueIdentifier
  }

  /**
  fetchOrImportObjectWithData:context:

  :param: data [String:AnyObject]
  :param: context NSManagedObjectContext

  :returns: NetworkDevice?
  */
  override class func fetchOrImportObjectWithData(data: [String:AnyObject], context: NSManagedObjectContext) -> NetworkDevice? {

    var device: NetworkDevice?

    // Try getting the type of device to import
    if let type = data["type"] as? String {

      var entityName: String?
      var deviceType: NetworkDevice.Type = NetworkDevice.self

      // Import with parameters derived from specified type
      switch type {
        case "itach":
          device = importObjectForEntity("ITachDevice", forType: ITachDevice.self, fromData: data, context: context) as? NetworkDevice
        case "isy":
          device = importObjectForEntity("ISYDevice", forType: ISYDevice.self, fromData: data, context: context) as? NetworkDevice
        default:
          break
      }
    }

    return device
  }
  class var rootCategory: Bank.RootCategory {
    let networkDevices = findAllSortedBy("name", ascending: true, context: DataManager.rootContext) as? [NetworkDevice]
    return Bank.RootCategory(label: "Network Devices",
                             icon: UIImage(named: "937-wifi-signal")!,
                             items: networkDevices ?? [],
                             editableItems: true)
  }

}

extension NetworkDevice: MSJSONExport {

  override func JSONDictionary() -> MSDictionary {
    let dictionary = super.JSONDictionary()
      safeSetValue(uniqueIdentifier, forKey: "unique-identifier", inDictionary: dictionary)
      dictionary.compact()
      dictionary.compress()
      return dictionary
  }

}
