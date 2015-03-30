//
//  Remote.swift
//  Remote
//
//  Created by Jason Cardwell on 11/16/14.
//  Copyright (c) 2014 Moondeer Studios. All rights reserved.
//

import Foundation
import CoreData
import MoonKit

@objc(Remote)
public final class Remote: RemoteElement {

  override public var elementType: BaseType { return .Remote }

  public var topBarHidden: Bool {
    get {
      willAccessValueForKey("topBarHidden")
      let topBarHidden = (primitiveValueForKey("topBarHidden") as? NSNumber)?.boolValue ?? false
      didAccessValueForKey("topBarHidden")
      return topBarHidden
    }
    set {
      willChangeValueForKey("topBarHidden")
      setPrimitiveValue(newValue, forKey: "topBarHidden")
      didChangeValueForKey("topBarHidden")
    }
  }
  @NSManaged public var activity: Activity?

  public var panels: [NSNumber:String] {
    get {
      willAccessValueForKey("panels")
      let panels = primitiveValueForKey("panels") as? [NSNumber:String]
      didAccessValueForKey("panels")
      return panels ?? [:]
    }
    set {
      willChangeValueForKey("panels")
      setPrimitiveValue(newValue, forKey: "panels")
      didChangeValueForKey("panels")
    }
  }

  override public var parentElement: RemoteElement? { get { return nil } set {} }

  /**
  updateWithPreset:

  :param: preset Preset
  */
  override func updateWithPreset(preset: Preset) {
    super.updateWithPreset(preset)

    topBarHidden = preset.topBarHidden ?? false
  }

  /**
  setButtonGroup:forPanelAssignment:

  :param: buttonGroup ButtonGroup?
  :param: assignment ButtonGroup.PanelAssignment
  */
  public func setButtonGroup(buttonGroup: ButtonGroup?, forPanelAssignment assignment: ButtonGroup.PanelAssignment) {
    var assignments = panels
    if assignment != ButtonGroup.PanelAssignment.Unassigned { assignments[assignment.rawValue] = buttonGroup?.uuid }
    panels = assignments
  }

  /**
  buttonGroupForPanelAssignment:

  :param: assignment ButtonGroup.PanelAssignment

  :returns: ButtonGroup?
  */
  public func buttonGroupForPanelAssignment(assignment: ButtonGroup.PanelAssignment) -> ButtonGroup? {
    var buttonGroup: ButtonGroup?
    if managedObjectContext != nil {
      if let uuid = panels[assignment.rawValue] {
        buttonGroup = ButtonGroup.objectWithUUID(uuid, context: managedObjectContext!)
      }
    }
    return buttonGroup
  }


  /**
  updateWithData:

  :param: data [String:AnyObject]
  */
  override public func updateWithData(data: [String:AnyObject]) {
    super.updateWithData(data)

    if let moc = managedObjectContext {

      if let topBarHidden = data["top-bar-hidden"] as? NSNumber { self.topBarHidden = topBarHidden.boolValue }

      if let panels = data["panels"] as? [String:String] {
        for (key, uuid) in panels {
          if let buttonGroup = subelements.objectPassingTest({($0.0 as! RemoteElement).uuid == uuid}) as? ButtonGroup {
            let assignment = ButtonGroup.PanelAssignment(JSONValue: key)
            if assignment != ButtonGroup.PanelAssignment.Unassigned {
              setButtonGroup(buttonGroup, forPanelAssignment: assignment)
            }
          }
        }
      }

    }

  }

  /**
  JSONDictionary

  :returns: MSDictionary
  */
  override public func JSONDictionary() -> MSDictionary {
    let dictionary = super.JSONDictionary()

    let panels = MSDictionary()

    for (number, uuid) in panels {
      let assignment = ButtonGroup.PanelAssignment(rawValue: number.integerValue)
      if let commentedUUID = buttonGroupForPanelAssignment(assignment)?.commentedUUID {
        panels[assignment.JSONValue] = commentedUUID
      }
    }

    if panels.count > 0 { dictionary["panels"] = panels }

    dictionary.compact()
    dictionary.compress()

    return dictionary
  }

}