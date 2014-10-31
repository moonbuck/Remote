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
  @NSManaged var primitiveCodeSets: NSSet
  var codeSets: [IRCodeSet] {
    get {
      willAccessValueForKey("codeSets")
      let codeSets = primitiveCodeSets.allObjects as? [IRCodeSet]
      didAccessValueForKey("codeSets")
      return codeSets ?? []
    }
    set {
      willChangeValueForKey("codeSets")
      primitiveCodeSets = NSSet(array: newValue)
      didChangeValueForKey("codeSets")
    }
  }
  @NSManaged var primitiveDevices: NSSet
  var devices: [ComponentDevice] {
    get {
      willAccessValueForKey("devices")
      let devices = primitiveDevices.allObjects as? [ComponentDevice]
      didAccessValueForKey("devices")
      return devices ?? []
    }
    set {
      willChangeValueForKey("devices")
      primitiveDevices = NSSet(array: newValue)
      didChangeValueForKey("devices")
    }
  }

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

  class var rootCategory: Bank.RootCategory {
    let manufacturers = findAllSortedBy("name", ascending: true) as? [Manufacturer]
    return Bank.RootCategory(label: "Manufacturers",
                             icon: UIImage(named: "1022-factory")!,
                             items: manufacturers ?? [],
                             editableItems: true)
  }

  override class func isEditable()      -> Bool { return true  }
  override class func isPreviewable()   -> Bool { return false }

  override func detailController() -> UIViewController {
    return ManufacturerDetailController(item: self)!
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