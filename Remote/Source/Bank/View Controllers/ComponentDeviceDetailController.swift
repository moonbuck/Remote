//
//  ComponentDeviceDetailController.swift
//  Remote
//
//  Created by Jason Cardwell on 9/26/14.
//  Copyright (c) 2014 Moondeer Studios. All rights reserved.
//

import Foundation
import UIKit
import MoonKit

class ComponentDeviceDetailController: BankItemDetailController {

  var componentDevice: ComponentDevice { return item as ComponentDevice }

  /**
  initWithItem:editing:

  :param: item BankableModelObject
  */
  required init?(item: BankDisplayItemModel) {
    super.init(item: item)
    precondition(item is ComponentDevice, "we should have been given a component device")

    /// Manufacturer
    ////////////////////////////////////////////////////////////////////////////////

    let moc = self.componentDevice.managedObjectContext!

    let manufacturerSection = BankItemDetailSection(sectionNumber: 0)

    manufacturerSection.addRow {
      let row = BankItemDetailButtonRow(pushableItem: self.componentDevice.manufacturer)
      row.name = "Manufacturer"
      row.pickerNilSelectionTitle = "No Manufacturer"
      row.pickerCreateSelectionTitle = "⨁ New Manufacturer"
      row.didSelectItem = {
        if !self.didCancel {
          self.componentDevice.manufacturer = $0 as? Manufacturer
          self.reloadRowsAtIndexPaths([NSIndexPath(forRow: 1, inSection: 0)])
        }
      }
      row.editActions = [UITableViewRowAction(style: .Default, title: "Clear", handler: {
        (action: UITableViewRowAction!, indexPath: NSIndexPath!) -> Void in
          self.componentDevice.manufacturer = nil
          self.reloadRowsAtIndexPaths([NSIndexPath(forRow: 0, inSection: 0), NSIndexPath(forRow: 1, inSection: 0)])
      })]
      row.pickerCreateSelectionHandler = {
        let alert = UIAlertController(title: "Create Manufacturer",
          message: "Enter a name for the manufacturer",
          preferredStyle: .Alert)
        alert.addTextFieldWithConfigurationHandler {
          $0.font = Bank.infoFont
          $0.textColor = Bank.infoColor
        }
        alert.addAction(UIAlertAction(title: "Cancel", style: .Cancel) {
          action in
          row.pickerSelection = self.componentDevice.manufacturer
          // re-select previous picker selection and dismiss picker
          self.dismissViewControllerAnimated(true, completion: nil)
        })
        alert.addAction(UIAlertAction(title: "Create", style: .Default) {
          action in
            if let text = (alert.textFields?.first as? UITextField)?.text {
              moc.performBlockAndWait {
                let manufacturer = Manufacturer.createInContext(moc)
                manufacturer.name = text
                self.componentDevice.manufacturer = manufacturer
                dispatch_async(dispatch_get_main_queue()) {
                  self.reloadRowsAtIndexPaths([NSIndexPath(forRow: 1, inSection: 0)])
                }
              }
            }
            self.dismissViewControllerAnimated(true, completion: nil)
        })

        self.presentViewController(alert, animated: true, completion: nil)
      }
      row.pickerData = sortedByName(Manufacturer.findAllInContext(moc) as? [Manufacturer])
      row.pickerSelection = self.componentDevice.manufacturer
      let manufacturerName = (row.pickerSelection as? Manufacturer)?.name ?? "No Manufacturer"
      println("row.pickerSelection = \(manufacturerName)")

      return row
    }

    manufacturerSection.addRow {

      let row = BankItemDetailButtonRow(pushableCategory: self.componentDevice.codeSet)
      row.name = "Code Set"
      row.pickerNilSelectionTitle = "No Code Set"
      row.pickerCreateSelectionTitle = "⨁ New Code Set"
      row.didSelectItem = {
        if !self.didCancel {
          self.componentDevice.codeSet = $0 as? IRCodeSet
          self.reloadRowsAtIndexPaths([NSIndexPath(forRow: 0, inSection: 0)])
        }
      }
      row.pickerCreateSelectionHandler = {
        let alert = UIAlertController(title: "Create Code Set",
          message: "Enter a name for the code set",
          preferredStyle: .Alert)
        alert.addTextFieldWithConfigurationHandler {
          $0.font = Bank.infoFont
          $0.textColor = Bank.infoColor
        }
        alert.addAction(UIAlertAction(title: "Cancel", style: .Cancel) {
          action in
          row.pickerSelection = self.componentDevice.codeSet
          // re-select previous picker selection and dismiss picker
          self.dismissViewControllerAnimated(true, completion: nil)
        })
        alert.addAction(UIAlertAction(title: "Create", style: .Default) {
          action in
          if let text = (alert.textFields?.first as? UITextField)?.text {
            moc.performBlockAndWait {
              let codeSet = IRCodeSet.createInContext(moc)
              codeSet.name = text
              codeSet.manufacturer = self.componentDevice.manufacturer
              self.componentDevice.codeSet = codeSet
            }
          }
          self.dismissViewControllerAnimated(true, completion: nil)
          })

        self.presentViewController(alert, animated: true, completion: nil)
      }
      row.pickerSelection = self.componentDevice.codeSet
      row.pickerData = sortedByName(self.componentDevice.manufacturer?.codeSets?.allObjects as? [IRCodeSet] ?? [])

      return row
    }


    /// Network Device
    ////////////////////////////////////////////////////////////////////////////////

    let networkDeviceSection = BankItemDetailSection(sectionNumber: 1, title: "Network Device")

    networkDeviceSection.addRow {
      let row = BankItemDetailButtonRow()
      row.selectionHandler = {
          if let networkDevice = self.componentDevice.networkDevice {
            self.navigationController?.pushViewController(networkDevice.detailController(), animated: true)
          }
        }
      row.name = "Network Device"
      row.info = self.componentDevice.networkDevice
      row.pickerNilSelectionTitle = "No Network Device"
      row.didSelectItem = { if !self.didCancel { self.componentDevice.networkDevice = $0 as? NetworkDevice } }
      row.pickerData = sortedByName(NetworkDevice.findAllInContext(moc) as? [NetworkDevice])
      row.pickerSelection = self.componentDevice.networkDevice

      return row
    }

    networkDeviceSection.addRow {
      let row = BankItemDetailStepperRow(identifier: .Stepper)
      row.name = "Port"
      row.info = Int(self.componentDevice.port)
      row.stepperMinValue = 1
      row.stepperMaxValue = 3
      row.stepperWraps = true
      row.valueDidChange = { if let n = $0 as? NSNumber { self.componentDevice.port = n.shortValue } }

      return row
    }

    /// Power
    ////////////////////////////////////////////////////////////////////////////////

    let powerSection = BankItemDetailSection(sectionNumber: 2, title: "Power")

    powerSection.addRow {
      let row = BankItemDetailButtonRow()
      row.name = "On"
      row.info = self.componentDevice.onCommand
      row.pickerNilSelectionTitle = "No On Command"
      row.pickerSelection = self.componentDevice.onCommand?.code
      row.didSelectItem = {
        (selection: NSObject?) -> Void in
          if !self.didCancel {
            moc.performBlock {
              if let code = selection as? IRCode {
                if let command = self.componentDevice.onCommand {
                  command.code = code
                } else {
                  let command = SendIRCommand(inContext: moc)
                  command.code = code
                  self.componentDevice.onCommand = command
                }
              } else {
                self.componentDevice.onCommand = nil
              }
            }
          }
      }
      row.pickerData = self.componentDevice.codeSet?.items as? [IRCode]

      return row
    }

    powerSection.addRow {
      let row = BankItemDetailButtonRow()
      row.name = "Off"
      row.info = self.componentDevice.offCommand
      row.pickerNilSelectionTitle = "No Off Command"
      row.pickerSelection = self.componentDevice.offCommand?.code
      row.didSelectItem = {
        (selection: NSObject?) -> Void in
          if !self.didCancel {
            moc.performBlock {
              if let code = selection as? IRCode {
                if let command = self.componentDevice.offCommand {
                  command.code = code
                } else {
                  let command = SendIRCommand(inContext: moc)
                  command.code = code
                  self.componentDevice.offCommand = command
                }
              } else {
                self.componentDevice.offCommand = nil
              }
            }
          }
      }
      row.pickerData = self.componentDevice.codeSet?.items as? [IRCode]

      return row
    }


    // Inputs
    ////////////////////////////////////////////////////////////////////////////////////////////////////

    let inputsSection = BankItemDetailSection(sectionNumber: 3, title: "Inputs")

    inputsSection.addRow {
      let row = BankItemDetailSwitchRow(identifier: .Switch)
      row.name = "Inputs Power On Device"
      row.info = NSNumber(bool: self.componentDevice.inputPowersOn)
      row.valueDidChange = { self.componentDevice.inputPowersOn = $0 as Bool }

      return row
    }

    for input in sortedByName(self.componentDevice.inputs) {
      inputsSection.addRow { return BankItemDetailListRow(pushableItem: input) }
    }

    /// Create the sections
    ////////////////////////////////////////////////////////////////////////////////

    sections = [manufacturerSection, networkDeviceSection, powerSection, inputsSection]
  }

  /**
  init:

  :param: aDecoder NSCoder
  */
  required init(coder aDecoder: NSCoder) { super.init(coder: aDecoder) }

  /**
  init:bundle:

  :param: nibNameOrNil String?
  :param: nibBundleOrNil NSBundle?
  */
  override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: NSBundle?) {
    super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
  }

  /**
  initWithStyle:

  :param: style UITableViewStyle
  */
  override init(style: UITableViewStyle) { super.init(style: style) }

}
