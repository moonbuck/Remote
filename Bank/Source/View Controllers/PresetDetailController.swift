//
//  PresetDetailController.swift
//  Remote
//
//  Created by Jason Cardwell on 9/26/14.
//  Copyright (c) 2014 Moondeer Studios. All rights reserved.
//

import Foundation
import UIKit
import MoonKit
import DataModel
import UI

// TODO: Cancel needs to reset any changed color values

class PresetDetailController: BankItemDetailController {

  private struct SectionKey {
    static let Preview          = "Preview"
    static let CommonAttributes = "Common Attributes"
  }

  private struct RowKey {
    static let Preview              = "Preview"
    static let Category             = "Category"
    static let BaseType             = "Base Type"
    static let Role                 = "Role"
    static let Shape                = "Shape"
    static let Style                = "Style"
    static let BackgroundImage      = "Background Image"
    static let BackgroundImageAlpha = "Background Image Alpha"
    static let BackgroundColor      = "Background Color"
  }

  /** loadSections() */
  override func loadSections() {
    super.loadSections()

    precondition(model is Preset, "we should have been given a preset")

    loadPreviewSection()
    loadCommonAttributesSection()
    // TODO: subelements
    // TODO: constraints

  }

  var element: RemoteElement?

  /** save */
  override func save() {
    // TODO: Handle saving preset but deleting temporary remote element created for view
    setEditing(false, animated: true)
  }

  /** loadPreviewSection */
  private func loadPreviewSection() {

    let previewSection = DetailSection(section: 0)

    previewSection.addRow({
      let row = DetailCustomRow()
      if let e = self.element { e.managedObjectContext?.deleteObject(e) }
      row.generateCustomView = {
        if let view = RemoteElementView.viewWithPreset(self.model as! Preset) {
          self.element = view.model
          return view
        } else {
          MSLogError("unable to create `RemoteElementView` from preset")
          return UIView()
        }
      }
      return row
      }, forKey: RowKey.Preview)

    sections[SectionKey.Preview] = previewSection
  }

  /** loadCommonAttributesSection */
  private func loadCommonAttributesSection() {

    let preset = model as! Preset

    let commonAttributesSection = DetailSection(section: 1, title: "Common Attributes")

    commonAttributesSection.addRow({
      let row = DetailLabelRow()
      row.name = "Category"
      row.info = preset.presetCategory
      row.select = DetailRow.selectPushableCollection(preset.presetCategory)
      return row
      }, forKey: RowKey.Category)

    let baseType = preset.baseType

    commonAttributesSection.addRow({
      let row = DetailLabelRow()
      row.name = "Base Type"
      row.info = baseType.stringValue.titlecaseString
      return row
      }, forKey: RowKey.BaseType)

    var roles: [RemoteElement.Role]

    switch baseType {
    case .Button: roles = RemoteElement.Role.buttonRoles
    case .ButtonGroup: roles = RemoteElement.Role.buttonGroupRoles
    default: roles = [.Undefined]
    }

    commonAttributesSection.addRow({
      let row = DetailButtonRow()
      row.name = "Role"
      row.info = preset.role.stringValue.titlecaseString

      var pickerRow = DetailPickerRow()
      pickerRow.titleForInfo = {($0 as! String).titlecaseString}
      pickerRow.data = roles.map{$0.stringValue}
      pickerRow.info = preset.role.stringValue
      pickerRow.didSelectItem = {
        if !self.didCancel {
          preset.role = RemoteElement.Role(($0 as! String).jsonValue) ?? .Undefined
          self.cellDisplayingPicker?.info = ($0 as! String).titlecaseString
          pickerRow.info = $0
        }
      }

      row.detailPickerRow = pickerRow

      return row
      }, forKey: RowKey.Role)

    if [.ButtonGroup, .Button] ∋ baseType {

      commonAttributesSection.addRow({
        let row = DetailButtonRow()
        row.name = "Shape"
        row.info = preset.shape.stringValue.titlecaseString

        var pickerRow = DetailPickerRow()
        pickerRow.didSelectItem = {
          if !self.didCancel {
            preset.shape = RemoteElement.Shape(($0 as! String).jsonValue) ?? .Undefined
            self.cellDisplayingPicker?.info = ($0 as! String).titlecaseString
            pickerRow.info = $0
          }
        }
        pickerRow.titleForInfo = {($0 as! String).titlecaseString}
        pickerRow.data = RemoteElement.Shape.allShapes.map{$0.stringValue}
        pickerRow.info = preset.shape.stringValue

        row.detailPickerRow = pickerRow

        return row
        }, forKey: RowKey.Shape)

      commonAttributesSection.addRow({
        let row = DetailTextFieldRow()
        row.name = "Style"
        row.info = preset.style.stringValue.capitalizedString
        row.placeholderText = "None"
        row.valueDidChange = { preset.style = RemoteElement.Style(($0 as! String).lowercaseString.jsonValue) ?? .None }

        return row
        }, forKey: RowKey.Style)
    }

    commonAttributesSection.addRow({
      let row = DetailLabeledImageRow()
      row.name = "Background Image"
      row.info = preset.backgroundImage?.preview
      row.placeholderImage = DrawingKit.imageOfNoImage(frame: CGRect(size: CGSize(square: 32.0)))
      return row
      }, forKey: RowKey.BackgroundImage)

    commonAttributesSection.addRow({
      let row = DetailSliderRow()
      row.name = "Background Image Alpha"
      row.info = preset.backgroundImageAlpha
      row.sliderStyle = .Gradient(.Alpha)
      row.valueDidChange = { preset.backgroundImageAlpha = ($0 as! NSNumber).floatValue }
      return row
      }, forKey: RowKey.BackgroundImageAlpha)

    commonAttributesSection.addRow({
      let row = DetailColorRow()
      row.name = "Background Color"
      row.info = preset.backgroundColor
      row.valueDidChange = { preset.backgroundColor = $0 as? UIColor }
      return row
      }, forKey: RowKey.BackgroundColor)
    
    sections[SectionKey.CommonAttributes] = commonAttributesSection
    
  }
  
}
