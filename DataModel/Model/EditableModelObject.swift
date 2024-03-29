//
//  EditableModelObject.swift
//  Remote
//
//  Created by Jason Cardwell on 3/20/15.
//  Copyright (c) 2015 Moondeer Studios. All rights reserved.
//

import Foundation
import CoreData
import MoonKit

public class EditableModelObject: IndexedModelObject, EditableModel {
  @NSManaged public var user: Bool

  /** save */
  public func save() { if let moc = managedObjectContext { DataManager.saveContext(moc, propagate: true) } }

  /** delete */
  public func delete() {
    if let moc = self.managedObjectContext { DataManager.saveContext(moc, withBlockAndWait: {$0.deleteObject(self)}) }
  }

  // TODO: Returning true for all Editable model objects, this should not be the case when shipping app
  public var editable: Bool { return true } //user }

  /** rollback */
  public func rollback() { if let moc = self.managedObjectContext { moc.performBlockAndWait { moc.rollback() } } }
  
  /**
  updateWithData:

  :param: data ObjectJSONValue
  */
  override public func updateWithData(data: ObjectJSONValue) {
    super.updateWithData(data)
    if let user = Bool(data["user"]) { self.user = user }
  }

  override public var jsonValue: JSONValue {
    var obj = ObjectJSONValue(super.jsonValue)!
    obj["user"] = user.jsonValue
    return obj.jsonValue
  }

  override public var description: String { return "\(super.description)\n\tuser = \(user)" }
}
