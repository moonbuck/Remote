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

public typealias NamedModel = protocol<Model, DynamicallyNamed>

public class NamedModelObject: ModelObject, NamedModel {

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
      var n = primitiveValueForKey("name") as? String
      didAccessValueForKey("name")
      return n ?? autoGeneratedName
    }
    set {
      var shouldSetName = true
      if self.dynamicType.requiresUniqueNaming() {
        if self.dynamicType.objectExistsWithName(newValue) { shouldSetName = false }
      }
      if shouldSetName {
        willChangeValueForKey("name")
        setPrimitiveValue(newValue, forKey: "name")
        didChangeValueForKey("name")
      }
    }
  }

  public var commentedUUID: String { var uuid = self.uuid; uuid.comment = "// \(name)"; return uuid }

  /**
  requiresUniqueNaming

  :returns: Bool
  */
  public class func requiresUniqueNaming() -> Bool { return false }

  /**
  updateWithData:

  :param: data [String:AnyObject]
  */
  override public func updateWithData(data: [String:AnyObject]) {
    super.updateWithData(data)
    if let n = data["name"] as? String { name = n }
  }

  /**
  JSONDictionary

  :returns: MSDictionary!
  */
  override public func JSONDictionary() -> MSDictionary {
    let dictionary = super.JSONDictionary()
    dictionary["name"] = name
    return dictionary
  }

  /**
  autoGenerateName

  :returns: String
  */
  func autoGenerateName() -> String { return className }

  var isNameAutoGenerated: Bool { return primitiveValueForKey("name") as? String == nil }

  /**
  objectExistsWithName:

  :param: name String

  :returns: Bool
  */
  public class func objectExistsWithName(name: String) -> Bool { return existingNames.contains(name) }

  public class var existingNames: Set<String> {
    let fetchRequest = NSFetchRequest(entityName: className())
    fetchRequest.resultType = .DictionaryResultType
    fetchRequest.propertiesToFetch = ["name", "autoGeneratedName"]
    var error: NSError?
    let moc = DataManager.mainContext()
    if let results = moc.executeFetchRequest(fetchRequest, error: &error) as? [[String:String]] {
      return Set(flattened(results.map{Array($0.values)}))
    }
    return Set()
  }

}
