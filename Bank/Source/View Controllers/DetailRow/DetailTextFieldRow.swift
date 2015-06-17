//
//  DetailTextFieldRow.swift
//  Remote
//
//  Created by Jason Cardwell on 10/22/14.
//  Copyright (c) 2014 Moondeer Studios. All rights reserved.
//

import Foundation
import UIKit
import MoonKit

final class DetailTextFieldRow: DetailTextInputRow {

  override var identifier: DetailCell.Identifier { return .TextField }

  var inputType: DetailTextFieldCell.InputType?
  var placeholderText: String?
  var placeholderAttributedText: NSAttributedString?
  var leftView: ((Void) -> UIView)?
  var rightView: ((Void) -> UIView)?
  var leftViewMode: UITextFieldViewMode?
  var rightViewMode: UITextFieldViewMode?
  
  /**
  configure:

  - parameter cell: DetailCell
  */
  override func configureCell(cell: DetailCell) {
    super.configureCell(cell)
    if let textFieldCell = cell as? DetailTextFieldCell {
      if inputType != nil { textFieldCell.inputType = inputType! }
      textFieldCell.placeholderText = placeholderText
      textFieldCell.placeholderAttributedText = placeholderAttributedText
      textFieldCell.leftView = leftView?()
      textFieldCell.rightView = rightView?()
      textFieldCell.leftViewMode = leftViewMode
      textFieldCell.rightViewMode = rightViewMode
    }
  }

}
