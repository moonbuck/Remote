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
class Remote: RemoteElement {

  /**
  elementType

  :returns: BaseType
  */
   override func elementType() -> BaseType { return .Remote }

  @NSManaged var topBarHidden: Bool
  @NSManaged var activity: Activity?

  @NSManaged var primitivePanels: NSDictionary
  var panelAssignments: [NSNumber:String] {
    get {
      willAccessValueForKey("panels")
      let panels = primitivePanels as? [NSNumber:String]
      didAccessValueForKey("panels")
      return panels ?? [:]
    }
    set {
      willChangeValueForKey("panels")
      primitivePanels = newValue
      didChangeValueForKey("panels")
    }
  }

  override var parentElement: RemoteElement? { get { return nil } set {} }

  /**
  setButtonGroup:forPanelAssignment:

  :param: buttonGroup ButtonGroup?
  :param: assignment ButtonGroup.PanelAssignment
  */
  func setButtonGroup(buttonGroup: ButtonGroup?, forPanelAssignment assignment: ButtonGroup.PanelAssignment) {
    var panels = panelAssignments
    if assignment != ButtonGroup.PanelAssignment.Unassigned { panels[assignment.rawValue] = buttonGroup?.uuid }
    panelAssignments = panels
  }

  /**
  buttonGroupForPanelAssignment:

  :param: assignment ButtonGroup.PanelAssignment

  :returns: ButtonGroup?
  */
  func buttonGroupForPanelAssignment(assignment: ButtonGroup.PanelAssignment) -> ButtonGroup? {
    var buttonGroup: ButtonGroup?
    if managedObjectContext != nil {
      if let uuid = panelAssignments[assignment.rawValue] {
        buttonGroup = ButtonGroup.existingObjectWithUUID(uuid, context: managedObjectContext!)
      }
    }
    return buttonGroup
  }


  /**
  updateWithData:

  :param: data [NSObject AnyObject]
  */
  override func updateWithData(data: [NSObject:AnyObject]) {
    super.updateWithData(data)

    if let moc = managedObjectContext {

      if let topBarHidden = data["top-bar-hidden"] as? NSNumber { self.topBarHidden = topBarHidden.boolValue }

      if let panels = data["panels"] as? [String:String] {
        for (key, uuid) in panels {
          if let buttonGroup = memberOfCollectionWithUUID(subelements, uuid) as? ButtonGroup {
            let n = countElements(key)
            if n > 4 {
              let location = key[0 ..< (n - 1)]
              let trigger = key[(n - 1) ..< n]
              var assignment = ButtonGroup.PanelAssignment.Unassigned
              switch location {
                case "top":    assignment.location = .Top
                case "bottom": assignment.location = .Bottom
                case "left":   assignment.location = .Left
                case "right":  assignment.location = .Right
                default: break
              }
              switch trigger {
                case "1": assignment.trigger = .OneFinger
                case "2": assignment.trigger = .TwoFinger
                case "3": assignment.trigger = .ThreeFinger
                default: break
              }
              if assignment != .Unassigned { setButtonGroup(buttonGroup, forPanelAssignment: assignment) }
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
  override func JSONDictionary() -> MSDictionary {
    let dictionary = super.JSONDictionary()

    let panels = MSDictionary()

    for (number, uuid) in panelAssignments {
      let assignment = ButtonGroup.PanelAssignment(rawValue: number.integerValue)
      if let commentedUUID = buttonGroupForPanelAssignment(assignment)?.commentedUUID {
        panels[assignment.JSONKey] = commentedUUID
      }
    }

    if panels.count > 0 { dictionary["panels"] = panels }

    dictionary.compact()
    dictionary.compress()

    return dictionary
  }

}