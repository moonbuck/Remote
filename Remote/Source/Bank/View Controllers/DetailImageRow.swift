//
//  DetailImageRow.swift
//  Remote
//
//  Created by Jason Cardwell on 10/22/14.
//  Copyright (c) 2014 Moondeer Studios. All rights reserved.
//

import Foundation
import UIKit
import MoonKit

struct DetailImageRow: DetailRow {

  let identifier: DetailCell.Identifier = .Image
  var indexPath: NSIndexPath?
  var select: ((Void) -> Void)?
  var delete: ((Void) -> Void)?

  var editActions: [UITableViewRowAction]?
  var editingStyle: UITableViewCellEditingStyle { return delete != nil || editActions != nil ? .Delete : .None }

  var deleteRemovesRow = true

  /// Properties that mirror `DetailCell` properties
  ////////////////////////////////////////////////////////////////////////////////

  var name: String? { get { return nil } set {} }
  var info: AnyObject?
  var infoDataType: DetailCell.DataType = .StringData
  var shouldAllowNonDataTypeValue: ((AnyObject?) -> Bool)?
  var valueDidChange: ((AnyObject?) -> Void)?
  var valueIsValid: ((AnyObject?) -> Bool)?
  var indentationLevel: Int = 0
  var indentationWidth: CGFloat = 8.0
  var backgroundColor: UIColor?

  /**
  configure:

  :param: cell DetailCell
  */
  func configureCell(cell: DetailCell, forTableView tableView: UITableView) {
    if !(cell is DetailImageCell) { return }
    if let color = backgroundColor { cell.backgroundColor = color }
    cell.indentationLevel = indentationLevel
    cell.indentationWidth = indentationWidth
    cell.info = info
    cell.infoDataType = infoDataType
    cell.valueIsValid = valueIsValid
    cell.valueDidChange = valueDidChange
    cell.sizeDidChange = {(cell: DetailCell) -> Void in tableView.beginUpdates(); tableView.endUpdates()}
    cell.shouldAllowNonDataTypeValue = shouldAllowNonDataTypeValue
  }

  /** init */
  init() {}

  /**
  initWithPreviewableItem:

  :param: previewableItem BankDisplayItemModel
  */
  init(previewableItem: PreviewableItem?) {
    info = previewableItem?.preview
  }

}
