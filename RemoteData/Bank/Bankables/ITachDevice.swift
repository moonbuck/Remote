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
class ITachDevice: NetworkDevice, Detailable {

  @NSManaged var primitiveConfigURL: String!
  var configURL: String! {
    get {
      willAccessValueForKey("configURL")
      let url = primitiveConfigURL
      didAccessValueForKey("configURL")
      return url
    }
    set {
      willChangeValueForKey("configURL")
      primitiveConfigURL = newValue.hasPrefix("http://") ? newValue[7..<newValue.length] : newValue
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

  @NSManaged var primitiveMake: String!
  var make: String! {
    get {
      willAccessValueForKey("make")
      let m = primitiveMake
      didAccessValueForKey("make")
      return m
    }
    set {
      willChangeValueForKey("make")
      primitiveMake = newValue
      didChangeValueForKey("make")
      if isNameAutoGenerated { if let n = generatedName { setPrimitiveValue(n, forKey: "name") } }
    }
  }

  @NSManaged var primitiveModel: String!
  var model: String! {
    get {
      willAccessValueForKey("model")
      let m = primitiveModel
      didAccessValueForKey("model")
      return m
    }
    set {
      willChangeValueForKey("model")
      primitiveModel = newValue
      didChangeValueForKey("model")
      if isNameAutoGenerated { if let n = generatedName { setPrimitiveValue(n, forKey: "name") } }
    }
  }

  @NSManaged var pcbPN: String
  @NSManaged var pkgLevel: String
  @NSManaged var revision: String
  @NSManaged var sdkClass: String
  @NSManaged var status: String

  /**
  updateWithData:

  :param: data [String:AnyObject]
  */
  override func updateWithData(data: [String:AnyObject]) {
    super.updateWithData(data)
    if let pcbPN     = data["pcb-pn"]     as? String { self.pcbPN = pcbPN }
    if let pkgLevel  = data["pkg-level"]  as? String { self.pkgLevel = pkgLevel }
    if let sdkClass  = data["sdk-class"]  as? String { self.sdkClass = sdkClass }
    if let make      = data["make"]       as? String { self.make = make }
    if let model     = data["model"]      as? String { self.model = model }
    if let status    = data["status"]     as? String { self.status = status }
    if let configURL = data["config-url"] as? String { self.configURL = configURL }
    if let revision  = data["revision"]   as? String { self.revision = revision }
  }

  /**
  detailController

  :returns: UIViewController
  */
  func detailController() -> UIViewController { return ITachDeviceDetailController(model: self) }

}

extension ITachDevice: MSJSONExport {

  override func JSONDictionary() -> MSDictionary {
    let dictionary = super.JSONDictionary()
    safeSetValue(pcbPN,     forKey: "pcb-pn",     inDictionary: dictionary)
    safeSetValue(pkgLevel,  forKey: "pkg-level",  inDictionary: dictionary)
    safeSetValue(sdkClass,  forKey: "sdk-class",  inDictionary: dictionary)
    safeSetValue(make,      forKey: "make",       inDictionary: dictionary)
    safeSetValue(model,     forKey: "model",      inDictionary: dictionary)
    safeSetValue(status,    forKey: "status",     inDictionary: dictionary)
    safeSetValue(configURL, forKey: "config-url", inDictionary: dictionary)
    safeSetValue(revision,  forKey: "revision",   inDictionary: dictionary)
    dictionary.compact()
    dictionary.compress()
    return dictionary
  }

}