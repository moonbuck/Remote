//
//  BankItemDetailTextInputRow.swift
//  Remote
//
//  Created by Jason Cardwell on 10/22/14.
//  Copyright (c) 2014 Moondeer Studios. All rights reserved.
//

import Foundation
import UIKit
import MoonKit

class BankItemDetailTextInputRow: BankItemDetailRow {

  var returnKeyType: UIReturnKeyType = .Done
  var keyboardType: UIKeyboardType = .ASCIICapable
  var autocapitalizationType: UITextAutocapitalizationType = .None
  var autocorrectionType: UITextAutocorrectionType = .No
  var spellCheckingType: UITextSpellCheckingType = .No
  var enablesReturnKeyAutomatically: Bool = false
  var keyboardAppearance: UIKeyboardAppearance = Bank.keyboardAppearance
  var secureTextEntry: Bool = false

  /**
  configureCell:forTableView:

  :param: cell BankItemCell
  :param: tableView UITableView
  */
  override func configureCell(cell: BankItemCell, forTableView tableView: UITableView) {
  	super.configureCell(cell, forTableView: tableView)
    cell.name = name
  	if let textFieldCell = cell as? BankItemTextFieldCell {
      textFieldCell.returnKeyType = returnKeyType
      textFieldCell.keyboardType = keyboardType
      textFieldCell.autocapitalizationType = autocapitalizationType
      textFieldCell.autocorrectionType = autocorrectionType
      textFieldCell.spellCheckingType = spellCheckingType
      textFieldCell.enablesReturnKeyAutomatically = enablesReturnKeyAutomatically
      textFieldCell.keyboardAppearance = keyboardAppearance
      textFieldCell.secureTextEntry = secureTextEntry
    } else if let textViewCell = cell as? BankItemTextViewCell {
      textViewCell.returnKeyType = returnKeyType
      textViewCell.keyboardType = keyboardType
      textViewCell.autocapitalizationType = autocapitalizationType
      textViewCell.autocorrectionType = autocorrectionType
      textViewCell.spellCheckingType = spellCheckingType
      textViewCell.enablesReturnKeyAutomatically = enablesReturnKeyAutomatically
      textViewCell.keyboardAppearance = keyboardAppearance
      textViewCell.secureTextEntry = secureTextEntry
    }
  }

}