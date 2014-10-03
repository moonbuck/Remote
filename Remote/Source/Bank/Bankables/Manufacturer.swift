//
//  Manufacturer.swift
//  Remote
//
//  Created by Jason Cardwell on 9/30/14.
//  Copyright (c) 2014 Moondeer Studios. All rights reserved.
//

import Foundation
import CoreData
import MoonKit

@objc(Manufacturer)
class Manufacturer: BankableModelObject {

  @NSManaged var codes: NSSet
  @NSManaged var codeSets: NSSet
  @NSManaged var devices: NSSet

  class func manufacturerWithName(name: String, context: NSManagedObjectContext) -> Manufacturer {
    var manufacturer: Manufacturer!
    context.performBlockAndWait { () -> Void in
      manufacturer = self.findFirstByAttribute("name", withValue: name, context: context)
      if manufacturer == nil {
        manufacturer = self.createInContext(context)
        manufacturer.name = name
      }
    }
    return manufacturer
  }

  override func updateWithData(data: [NSObject : AnyObject]!) {
    super.updateWithData(data)
    if let codeSets = IRCodeSet.importObjectsFromData(data["codesets"], context: managedObjectContext) as? [IRCodeSet] {
      mutableSetValueForKey("codeSets").addObjectsFromArray(codeSets)
      mutableSetValueForKey("codes").addObjectsFromArray(flattened(codeSets.map{$0.codes}‽.map{$0.allObjects as [IRCode]}))
    }
    if let devices = ComponentDevice.importObjectsFromData(data["devices"],
                                                   context: managedObjectContext) as? [ComponentDevice]
    {
      mutableSetValueForKey("devices").addObjectsFromArray(devices)
    }
  }

}

extension Manufacturer: MSJSONExport {

  override func JSONDictionary() -> MSDictionary! {
    let dictionary = super.JSONDictionary()

    safeSetValueForKeyPath("codeSets.JSONDictionary", forKey: "codesets", inDictionary: dictionary)
    safeSetValueForKeyPath("devices.commentedUUID",   forKey: "devices",  inDictionary: dictionary)

    dictionary.compact()
    dictionary.compress()

    return dictionary
  }

}

extension Manufacturer: BankDisplayItem {

  override class func label() -> String   { return "Manufacturers"                }
  override class func icon()  -> UIImage? { return UIImage(named: "1022-factory") }

  override class func isThumbnailable() -> Bool { return false }
  override class func isDetailable()    -> Bool { return true  }
  override class func isEditable()      -> Bool { return true  }
  override class func isPreviewable()   -> Bool { return false }

}

extension Manufacturer: BankDisplayItemModel {

  override var detailController: DetailControllerType? { return ManufacturerDetailController(item: self, editing: false) }
  override var editingController: DetailControllerType? { return ManufacturerDetailController(item: self, editing: true) }

}
