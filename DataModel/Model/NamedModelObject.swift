//
//  NamedModelObject.swift
//  Remote
//
//  Created by Jason Cardwell on 10/18/14.
//  Copyright (c) 2014 Moondeer Studios. All rights reserved.
//

import Foundation
import CoreData
import MoonKit

public class NamedModelObject: ModelObject, NamedModel {

  public init(name: String, context: NSManagedObjectContext) {
    super.init(context: context)
    self.name = name
  }

  public override init(context: NSManagedObjectContext?) { super.init(context: context) }


  /**
  initWithEntity:insertIntoManagedObjectContext:

  - parameter entity: NSEntityDescription
  - parameter context: NSManagedObjectContext?
  */
  public override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
    super.init(entity: entity, insertIntoManagedObjectContext: context)
  }
  
  required public init?(data: ObjectJSONValue, context: NSManagedObjectContext) {
      super.init(data: data, context: context)
  }

  public var autoGeneratedName: String {
    get {
      willAccessValueForKey("autoGeneratedName")
      var n = primitiveValueForKey("autoGeneratedName") as? String
      didAccessValueForKey("autoGeneratedName")
      if n == nil || n!.isEmpty {
        let base = autoGenerateName()
        let existingNames = self.dynamicType.existingNames
        var count = existingNames.count
        n = "\(base) \(count)"
        while existingNames.contains(n!) { n = "\(base) \(++count)" }
        setPrimitiveValue(n!, forKey: "autoGeneratedName")
      }
      return n ?? ""
    }
    set {
      willChangeValueForKey("autoGeneratedName")
      setPrimitiveValue(newValue, forKey: "autoGeneratedName")
      didChangeValueForKey("autoGeneratedName")
    }
  }

  public var name: String {
    get {
      willAccessValueForKey("name")
      let n = primitiveValueForKey("name") as? String
      didAccessValueForKey("name")
      return n ?? autoGeneratedName
    }
    set {
      if !(self.dynamicType.requiresUniqueNaming() && self.dynamicType.objectExistsWithName(newValue)) {
        willChangeValueForKey("name")
        setPrimitiveValue(newValue, forKey: "name")
        didChangeValueForKey("name")
      }
    }
  }

  public var commentedUUID: String { let uuid = self.uuid; uuid.comment = "// \(name)"; return uuid }

  /**
  requiresUniqueNaming

  - returns: Bool
  */
  public class func requiresUniqueNaming() -> Bool { return false }

  /**
  updateWithData:

  - parameter data: ObjectJSONValue
  */
  override public func updateWithData(data: ObjectJSONValue) {
    super.updateWithData(data)
    if let n = String(data["name"]) { name = n }
  }

  override public var jsonValue: JSONValue { return (ObjectJSONValue(super.jsonValue)! + ("name", name)).jsonValue }

  /**
  autoGenerateName

  - returns: String
  */
  func autoGenerateName() -> String { return className }

  var isNameAutoGenerated: Bool { return primitiveValueForKey("name") as? String == nil }

  /**
  objectExistsWithName:

  - parameter name: String

  - returns: Bool
  */
  public class func objectExistsWithName(name: String) -> Bool { return existingNames.contains(name) }

  public class var existingNames: Set<String> {
    let fetchRequest = NSFetchRequest(entityName: className())
    fetchRequest.resultType = .DictionaryResultType
    fetchRequest.propertiesToFetch = ["name", "autoGeneratedName"]
    let moc = DataManager.rootContext
    do {
      if let results = try moc.executeFetchRequest(fetchRequest) as? [[String:String]] {
        return Set(flattened(results.map{Array($0.values)}))
      } else {
        return Set()
      }
    } catch {
      return Set()
    }
  }

  override public var description: String {
    return "\(super.description)\n\tname = \(name)" + (isNameAutoGenerated ? " (generated)" : "")
  }

}
