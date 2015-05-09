//
//  ITachDevice.swift
//  Remote
//
//  Created by Jason Cardwell on 10/1/14.
//  Copyright (c) 2014 Moondeer Studios. All rights reserved.
//

import Foundation
import CoreData
import MoonKit

@objc(ITachDevice)
public class ITachDevice: NetworkDevice {

  public var configURL: String! {
    get {
      willAccessValueForKey("configURL")
      let url = primitiveValueForKey("configURL") as? String
      didAccessValueForKey("configURL")
      return url ?? ""
    }
    set {
      willChangeValueForKey("configURL")
      setPrimitiveValue(newValue.hasPrefix("http://") ? newValue[7..<newValue.length] : newValue, forKey: "configURL")
      didChangeValueForKey("configURL")
    }
  }

  private var generatedName: String? {
    var n = ""
      if model != nil && !model.isEmpty { n += model }
      if make != nil && !make.isEmpty {
        if !n.isEmpty { n += "-" }
        n += make
      }
      return n.isEmpty ? nil : n
  }

  public var make: String! {
    get {
      willAccessValueForKey("make")
      let m = primitiveValueForKey("make") as? String
      didAccessValueForKey("make")
      return m ?? ""
    }
    set {
      willChangeValueForKey("make")
      setPrimitiveValue(newValue, forKey: "make")
      didChangeValueForKey("make")
      if isNameAutoGenerated { if let n = generatedName { setPrimitiveValue(n, forKey: "name") } }
    }
  }

  public var model: String! {
    get {
      willAccessValueForKey("model")
      let m = primitiveValueForKey("model") as? String
      didAccessValueForKey("model")
      return m ?? ""
    }
    set {
      willChangeValueForKey("model")
      setPrimitiveValue(newValue, forKey: "model")
      didChangeValueForKey("model")
      if isNameAutoGenerated { if let n = generatedName { setPrimitiveValue(n, forKey: "name") } }
    }
  }

  @NSManaged public var pcbPN: String
  @NSManaged public var pkgLevel: String
  @NSManaged public var revision: String
  @NSManaged public var sdkClass: String
  @NSManaged public var status: String

  /**
  updateWithData:

  :param: data ObjectJSONValue
  */
  override public func updateWithData(data: ObjectJSONValue) {
    super.updateWithData(data)
    if let pcbPN     = String(data["pcbPN"]) { self.pcbPN = pcbPN }
    if let pkgLevel  = String(data["pkgLevel"]) { self.pkgLevel = pkgLevel }
    if let sdkClass  = String(data["sdkClass"]) { self.sdkClass = sdkClass }
    if let make      = String(data["make"]) { self.make = make }
    if let model     = String(data["model"]) { self.model = model }
    if let status    = String(data["status"]) { self.status = status }
    if let configURL = String(data["configURL"]) { self.configURL = configURL }
    if let revision  = String(data["revision"]) { self.revision = revision }
  }

  override public var jsonValue: JSONValue {
    var obj = ObjectJSONValue(super.jsonValue)!
    obj["type"] = "itach"
    obj["pcbPN"] = pcbPN.jsonValue
    obj["pkgLevel"] = pkgLevel.jsonValue
    obj["sdkClass"] = sdkClass.jsonValue
    obj["make"] = make.jsonValue
    obj["model"] = model.jsonValue
    obj["status"] = status.jsonValue
    obj["configURL"] = configURL.jsonValue
    obj["revision"] = revision.jsonValue
    return obj.jsonValue
  }

}
