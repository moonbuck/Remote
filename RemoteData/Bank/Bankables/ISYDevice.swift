//
//  ISYDevice.swift
//  Remote
//
//  Created by Jason Cardwell on 10/1/14.
//  Copyright (c) 2014 Moondeer Studios. All rights reserved.
//

import Foundation
import CoreData
import MoonKit

/**

SOAP:

To turn off a light:

POST /services HTTP/1.1
HOST: 192.168.1.9
Content-Length: 239
Authorization: Basic bW9vbmRlZXI6MWJsdWViZWFy
Content-Type: text/xml; charset="utf-8"
SOAPACTION:"urn:udi-com:service:X_Insteon_Lighting_Service:1#UDIService"

<s:Envelope>
<s:Body>
<u:UDIService xmlns:u="urn:udi-com:service:X_Insteon_Lighting_Service:1">
<control>DOF</control>
<action></action>
<flag>65531</flag>
<node>1B 6E B2 1</node>
</u:UDIService>
</s:Body>
</s:Envelope>

To rename a node:

POST /services HTTP/1.1
HOST: 192.168.1.9
Content-Length: 239
Authorization: Basic bW9vbmRlZXI6MWJsdWViZWFy
Content-Type: text/xml; charset="utf-8"
SOAPACTION:"urn:udi-com:service:X_Insteon_Lighting_Service:1#UDIService"

<s:Envelope>
<s:Body>
<u:RenameNode xmlns:u="urn:udi-com:service:X_Insteon_Lighting_Service:1">
<id>1B 6E B2 1</id>
<name>Front Door Table Lamp</name>
</u:RenameNode>
</s:Body>
</s:Envelope>


REST:

To turn on a light:

http://192.168.1.9/rest/nodes/1B%206E%20B2%201/cmd/DON



*/
@objc(ISYDevice)
class ISYDevice: NetworkDevice, Detailable {

    @NSManaged var baseURL: String
    @NSManaged var deviceType: String
    @NSManaged var friendlyName: String
    @NSManaged var manufacturer: String
    @NSManaged var manufacturerURL: String
    @NSManaged var modelDescription: String
    @NSManaged var modelName: String
    @NSManaged var modelNumber: String
    @NSManaged var primitiveGroups: NSMutableSet?
    var groups: [ISYDeviceGroup] {
      get {
        willAccessValueForKey("groups")
        let groups = primitiveGroups?.allObjects as? [ISYDeviceGroup]
        didAccessValueForKey("groups")
        return groups ?? []
      }
      set {
        willChangeValueForKey("groups")
        primitiveGroups = NSMutableSet(array: newValue)
        didChangeValueForKey("groups")
      }
    }
    @NSManaged var primitiveNodes: NSMutableSet?
    var nodes: [ISYDeviceNode] {
      get {
        willAccessValueForKey("nodes")
        let nodes = primitiveNodes?.allObjects as? [ISYDeviceNode]
        didAccessValueForKey("nodes")
        return nodes ?? []
      }
      set {
        willChangeValueForKey("nodes")
        primitiveNodes = NSMutableSet(array: newValue)
        didChangeValueForKey("nodes")
      }
    }

  /**
  updateWithData:

  :param: data [String:AnyObject]
  */
  override func updateWithData(data: [String:AnyObject]) {
    super.updateWithData(data)
    if let modelNumber       = data["model-number"]      as? String { self.modelNumber = modelNumber }
    if let modelName         = data["model-name"]        as? String { self.modelName = modelName }
    if let modelDescription  = data["model-description"] as? String { self.modelDescription = modelDescription }
    if let manufacturerURL   = data["manufacturer-url"]  as? String { self.manufacturerURL = manufacturerURL }
    if let manufacturer      = data["manufacturer"]      as? String { self.manufacturer = manufacturer }
    if let friendlyName      = data["friendly-name"]     as? String { self.friendlyName = friendlyName }
    if let deviceType        = data["device-type"]       as? String { self.deviceType = deviceType }
    if let baseURL           = data["base-url"]          as? String { self.baseURL = baseURL }

    updateRelationshipFromData(data, forKey: "nodes")
    updateRelationshipFromData(data, forKey: "groups")
  }

  /**
  detailController

  :returns: UIViewController
  */
  func detailController() -> UIViewController { return ISYDeviceDetailController(model: self) }

}

extension ISYDevice: MSJSONExport {

  /**
  JSONDictionary

  :returns: MSDictionary!
  */
  override func JSONDictionary() -> MSDictionary {
    let dictionary = super.JSONDictionary()
      safeSetValue(modelNumber,      forKey: "model-number",      inDictionary: dictionary)
      safeSetValue(modelName,        forKey: "model-name",        inDictionary: dictionary)
      safeSetValue(modelDescription, forKey: "model-description", inDictionary: dictionary)
      safeSetValue(manufacturerURL,  forKey: "manufacturer-url",  inDictionary: dictionary)
      safeSetValue(manufacturer,     forKey: "manufacturer",      inDictionary: dictionary)
      safeSetValue(friendlyName,     forKey: "friendly-name",     inDictionary: dictionary)
      safeSetValue(deviceType,       forKey: "device-type",       inDictionary: dictionary)
      safeSetValue(baseURL,          forKey: "base-url",          inDictionary: dictionary)
      safeSetValueForKeyPath("nodes.JSONDictionary",  forKey: "nodes",  inDictionary: dictionary)
      safeSetValueForKeyPath("groups.JSONDictionary", forKey: "groups", inDictionary: dictionary)
      dictionary.compact()
      dictionary.compress()
      return dictionary
  }

}