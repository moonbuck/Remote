//
//  SendIRCommand.swift
//  Remote
//
//  Created by Jason Cardwell on 3/2/15.
//  Copyright (c) 2015 Moondeer Studios. All rights reserved.
//

import Foundation
import CoreData
import MoonKit

/**
  `SendIRCommand` subclasses `Command` to send IR commands via <ConnectionManager> to networked
  IR receivers that control the user's home theater system. At this time, only
  [iTach](http://www.globalcache.com/products/itach) devices from Global Caché are supported.
*/
@objc(SendIRCommand)
public final class SendIRCommand: SendCommand {

  @NSManaged public var code: IRCode

  public var port: Int16 { return componentDevice?.port ?? 0 }
  public var componentDevice: ComponentDevice? { return code.device }
  public var networkDevice: NetworkDevice? { return componentDevice?.networkDevice }

  public var commandString: String {
    return "sendir,1:\(port),<tag>,\(code.frequency),\(code.repeatCount),\(code.offset),\(code.onOffPattern)"
  }

  /**
  updateWithData:

  :param: data ObjectJSONValue
  */
  override public func updateWithData(data: ObjectJSONValue) {
    super.updateWithData(data)
  
    updateRelationshipFromData(data, forAttribute: "code")
  }

  override public var jsonValue: JSONValue {
    var obj = ObjectJSONValue(super.jsonValue)!
    obj["class"] = "sendir".jsonValue
    obj["code.index"] = code.index.jsonValue
    return obj.jsonValue
  }

}