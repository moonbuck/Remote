//
//  DetailLabelRow.swift
//  Remote
//
//  Created by Jason Cardwell on 10/22/14.
//  Copyright (c) 2014 Moondeer Studios. All rights reserved.
//

import Foundation
import UIKit
import MoonKit

class DetailLabelRow: DetailRow {

  override var identifier: DetailCell.Identifier { return .Label }

  /**
  configure:

  :param: cell DetailCell
  */
  override func configureCell(cell: DetailCell) {
    super.configureCell(cell)
  }

  /**
  initWithLabel:value:

  :param: label String
  :param: value String?
  */
  convenience init(label: String, value: String?) {
    self.init()
    name = label
    info = value
  }

  /**
  initWithPushableCategory:label:hasEditingState:

  :param: pushableCategory BankDisplayItemCategory
  :param: label String
  */
  convenience init(pushableCategory: BankDisplayItemCategory, label: String) {
    self.init()
    select = {
      if let controller = BankCollectionController(category: pushableCategory) {
        if let nav = MSRemoteAppController.sharedAppController().window.rootViewController as? UINavigationController {
          nav.pushViewController(controller, animated: true)
        }
      }
    }
    name = label
    info = pushableCategory
  }

  /** init */
  override init() { super.init() }

}
