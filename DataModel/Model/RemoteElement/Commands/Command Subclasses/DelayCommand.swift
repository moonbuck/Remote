//
//  DelayCommand.swift
//  Remote
//
//  Created by Jason Cardwell on 3/2/15.
//  Copyright (c) 2015 Moondeer Studios. All rights reserved.
//

import Foundation
import CoreData
import MoonKit

/**
  `DelayCommand` subclasses `Command` to provide a delay, usually in a chain of other commands.
*/
@objc(DelayCommand)
public final class DelayCommand: Command {

  @NSManaged public var duration: NSNumber

  /**
  updateWithData:

  :param: data [String:AnyObject]
  */
  override public func updateWithData(data: [String:AnyObject]) {
    super.updateWithData(data)
    if let duration = data["duration"] as? NSNumber { self.duration = duration }
  }

  /**
  JSONDictionary

  :returns: MSDictionary!
  */
  override public func JSONDictionary() -> MSDictionary {
    let dictionary = super.JSONDictionary()

    dictionary["class"] = "delay"
    appendValueForKey("duration", toDictionary: dictionary)

    dictionary.compact()
    dictionary.compress()

    return dictionary
  }

  override var operation: CommandOperation { return DelayCommandOperation(command: self) }
  
}