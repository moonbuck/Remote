//
//  BankProtocols.swift
//  Remote
//
//  Created by Jason Cardwell on 3/27/15.
//  Copyright (c) 2015 Moondeer Studios. All rights reserved.
//

import Foundation
import UIKit
import MoonKit
import DataModel

// MARK: - Detailable protocol and extensions
@objc protocol Detailable { func detailController() -> UIViewController }

extension ComponentDevice: Detailable {
  func detailController() -> UIViewController { return ComponentDeviceDetailController(model: self) }
}

extension Manufacturer: Detailable {
  func detailController() -> UIViewController { return ManufacturerDetailController(model: self) }
}

extension IRCode: Detailable {
  func detailController() -> UIViewController { return IRCodeDetailController(model: self) }
}

extension Image: Detailable {
  func detailController() -> UIViewController { return ImageDetailController(model: self) }
}

extension ISYDevice: Detailable {
  func detailController() -> UIViewController { return ISYDeviceDetailController(model: self) }
}

extension ITachDevice: Detailable {
  func detailController() -> UIViewController { return ITachDeviceDetailController(model: self) }
}

extension Preset: Detailable {
  func detailController() -> UIViewController {
    switch baseType {
      case .Remote: return RemotePresetDetailController(model: self)
      case .ButtonGroup: return ButtonGroupPresetDetailController(model: self)
      case .Button: return ButtonPresetDetailController(model: self)
      default: return PresetDetailController(model: self)
    }
  }
}

// MARK: - Previewable protocol and extensions
@objc protocol Previewable { var preview: UIImage? { get }; var thumbnail: UIImage? { get } }

extension Image: Previewable {}
extension Preset: Previewable {}

// MARK: - BankModelCollection protocol and extensions

@objc protocol BankModelCollection: Named {
  optional var items: [NamedModel] { get }
  optional var collections: [ModelCollection] { get }
  optional var previewable: Bool { get }
}

extension Manufacturer: BankModelCollection {}
extension IRCodeSet: BankModelCollection {}
extension ImageCategory: BankModelCollection {
  var previewable: Bool { return true }
}
extension PresetCategory: BankModelCollection {
  var previewable: Bool { return true }
}

// MARK: - View controller related protocols

/** Protocol for objects that want to present a bank item controller and receive a callback on item selection */
public protocol BankItemSelectionDelegate {
  func bankController(bankController: UIViewController, didSelectItem item: EditableModel)
}

/** Protocol for types that want to support a toolbar control for switching between viewing modes */
protocol BankItemSelectiveViewingModeController: class {
  var selectiveViewingEnabled: Bool { get }
  var viewingMode: Bank.ViewingMode { get set }
  weak var displayOptionsControl: ToggleImageSegmentedControl? { get set }
}

/** Protocol for types that want import/export bar button items in bottom toolbar */
protocol BankItemImportExportController: class {

  var exportSelection: [JSONValueConvertible] { get }
  var exportSelectionMode: Bool { get set }

  func selectAllExportableItems() // Called from select all bar button action
  func importFromFile(fileURL: NSURL)

}

/** Protocol for types that want create bar button item in bottom toolbar */
protocol BankItemCreationController: class {
  func createBankItem()  // Called from create item bar button action
}

/** Protocol for types that want search bar button item in bottom toolbar */
protocol BankItemSearchableController: class {
  func searchBankObjects()  // Called from search bar button action
}
