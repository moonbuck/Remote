//
//  NamedModelObject+Bank.swift
//  Remote
//
//  Created by Jason Cardwell on 5/17/15.
//  Copyright (c) 2014 Moondeer Studios. All rights reserved.
//

import Foundation
import DataModel
import CoreData
import MoonKit

extension NamedModelObject {

  /**
  nameFormFieldTemplate:

  :param: #context NSManagedObjectContext

  :returns: FieldTemplate
  */
  static func nameFormFieldTemplate(#context: NSManagedObjectContext) -> FieldTemplate {
    let placeholder = "The " + entityDescription.name!.dashcaseString.subbed("-", " ") + "'s name"
    let validation: (String?) -> Bool = {
      !($0 == nil   ||
        $0!.isEmpty ||
        self.countInContext(context, predicate: ∀"name == '\($0)' OR autoGeneratedName == '\($0)'") > 0)
    }
    return .Text(value: "", placeholder: placeholder, validation: validation, editable: true)
  }

  /**
  pickerFormFieldTemplate:

  :param: #context NSManagedObjectContext

  :returns: FieldTemplate
  */
  static func pickerFormFieldTemplate(#context: NSManagedObjectContext,
                             optional: Bool = true,
                             editable: Bool = true) -> FieldTemplate
  {
    var allValues = allValuesForAttribute("name", context: context) as! [String]
    allValues.sort(<)
    let choices = optional ? ["None"] + allValues : allValues
    let initial = choices[0]
    return .Picker(value: initial, choices: choices, editable: editable)
  }

}
