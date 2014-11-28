//
//  BankItemDetailTextViewRow.swift
//  Remote
//
//  Created by Jason Cardwell on 10/22/14.
//  Copyright (c) 2014 Moondeer Studios. All rights reserved.
//

import Foundation
import UIKit
import MoonKit

class BankItemDetailTextViewRow: BankItemDetailTextInputRow {

  var shouldAllowReturnsInTextView: Bool = false

  /**
  configureCell:forTableView:

  :param: cell BankItemCell
  :param: tableView UITableView
  */
  override func configureCell(cell: BankItemCell, forTableView tableView: UITableView) {
  	super.configureCell(cell, forTableView: tableView)
    cell.name = name
  	if let textViewCell = cell as? BankItemTextViewCell {
      textViewCell.shouldAllowReturnsInTextView = shouldAllowReturnsInTextView
    }
  }

  /** init */
  convenience init() { self.init(identifier: .TextView) }

}
