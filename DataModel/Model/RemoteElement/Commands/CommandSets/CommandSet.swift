//
//  CommandSet.swift
//  Remote
//
//  Created by Jason Cardwell on 3/2/15.
//  Copyright (c) 2015 Moondeer Studios. All rights reserved.
//

import Foundation
import CoreData
import MoonKit

@objc(CommandSet)
public final class CommandSet: CommandContainer {

  @NSManaged public var commands: NSSet?

  static let sharedKeysByType: [CommandSetType:Set<RemoteElement.Role>] = [
    .Dpad: Set<RemoteElement.Role>([.Up, .Down, .Left, .Right, .Center]),
    .Transport: Set<RemoteElement.Role>([.Play, .Stop, .Pause, .Skip, .Replay, .FF, .Rewind, .Record]),
    .Numberpad: Set<RemoteElement.Role>([.One, .Two, .Three, .Four, .Five, .Six, .Seven, .Eight, .Nine, .Zero, .Aux1, .Aux2]),
    .Rocker: Set<RemoteElement.Role>([.Top, .Bottom])
  ]

  @objc public enum CommandSetType: Int { case Unspecified, Dpad, Transport, Numberpad, Rocker }
  @NSManaged var primitiveType: NSNumber
  public var type: CommandSetType {
    get {
      willAccessValueForKey("type")
      let type = primitiveType
      didAccessValueForKey("type")
      return CommandSetType(rawValue: type.integerValue) ?? .Unspecified
    }
    set {
      willChangeValueForKey("type")
      primitiveType = newValue.rawValue
      didChangeValueForKey("type")
      if let sharedKeys = CommandSet.sharedKeysByType[newValue] {
        containerIndex = MSDictionary(sharedKeys: Array(map(sharedKeys){$0.rawValue}))
      } else {
        containerIndex = MSDictionary()
      }
    }
  }

  /**
  subscript:

  :param: key RemoteElement.Role

  :returns: Command?
  */
  public subscript(key: RemoteElement.Role) -> Command? {
    get { return containerIndex[key.rawValue] as? Command }
    set { containerIndex[key.rawValue] = newValue }
  }

  /**
  updateWithData:

  :param: data ObjectJSONValue
  */
  override public func updateWithData(data: ObjectJSONValue) {
    super.updateWithData(data)

    if let moc = managedObjectContext,
      let typeJSON = data["type"] as? String {
      let type = CommandSetType(jsonValue: typeJSON.jsonValue)
      if type != .Unspecified {
        self.type = type
        let commands = data - "type"
        for (roleJSON, roleData) in commands {
          if let commandData = roleData as? [String:AnyObject],
            let command: Command = Command.importObjectWithData(commandData, context: moc) {
              self[RemoteElement.Role(jsonValue: roleJSON.jsonValue)] = command
          }
        }
      }
    }
  }

  override public var jsonValue: JSONValue {
    var dict = super.jsonValue.value as! JSONValue.ObjectValue

    dict["type"] = type.jsonValue
    containerIndex.enumerateKeysAndObjectsUsingBlock { (key, uri, _) -> Void in
      if let command = self.managedObjectContext?.objectForURI(uri as! NSURL) as? Command {
        // TODO: This looks atrocious
        dict[RemoteElement.Role(rawValue: (key as! NSNumber).integerValue).jsonValue.value as! String] = command.jsonValue
      }
    }
    return .Object(dict)
  }


}

extension CommandSet.CommandSetType: JSONValueConvertible {
  public var jsonValue: JSONValue {
    switch self {
      case .Dpad:      return "dpad"
      case .Transport: return "transport"
      case .Numberpad: return "numberpad"
      case .Rocker:    return "rocker"
      default:         return "unspecified"
    }
  }

  public init(jsonValue: JSONValue) {
    switch jsonValue.value as? String {
      case let s where s == "dpad":      self = .Dpad
      case let s where s == "transport": self = .Transport
      case let s where s == "numberpad": self = .Numberpad
      case let s where s == "rocker":    self = .Rocker
      default:                           self = .Unspecified
    }
  }
}