//
//  BankSurrogateCategory.swift
//  Remote
//
//  Created by Jason Cardwell on 10/2/14.
//  Copyright (c) 2014 Moondeer Studios. All rights reserved.
//

import Foundation
import CoreData
import UIKit
import MoonKit

@objc(BankSurrogateCategory)
class BankSurrogateCategory: NSObject, BankDisplayItemCategory {

  let subcategories: [BankDisplayItemCategory]
  var parentCategory: BankDisplayItemCategory? { return nil }

	let items: [BankDisplayItemModel]
  let title: String

  let previewableItems:   Bool
  let editableItems:      Bool

  func save() {}
  func delete() {}
  func rollback() {}

  init(title: String,
       subcategories: [BankDisplayItemCategory] = [],
       items: [BankDisplayItemModel] = [],
       previewableItems: Bool = false,
       editableItems: Bool = false)
  {
    self.title = title
    self.subcategories = subcategories
    self.items = items
    self.previewableItems = previewableItems
    self.editableItems = editableItems
  }

}
