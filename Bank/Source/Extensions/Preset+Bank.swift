//
//  Preset+Bank.swift
//  Remote
//
//  Created by Jason Cardwell on 5/16/15.
//  Copyright (c) 2014 Moondeer Studios. All rights reserved.
//

import Foundation
import DataModel
import CoreData
import MoonKit

extension Preset: Previewable {}

extension Preset: Detailable {
  func detailController() -> UIViewController {
    switch baseType {
      case .Remote:      return RemotePresetDetailController(model: self)
      case .ButtonGroup: return ButtonGroupPresetDetailController(model: self)
      case .Button:      return ButtonPresetDetailController(model: self)
      default:           return PresetDetailController(model: self)
    }
  }
}

extension Preset: DelegateDetailable {
    func sectionIndexForController(controller: BankCollectionDetailController) -> BankModelDetailDelegate.SectionIndex {
      var sections: BankModelDetailDelegate.SectionIndex = [:]


      return sections
    }
}

// TODO: Fill out `FormCreatable` stubs
extension Preset: FormCreatable {

  /**
  creationForm:

  :param: #context NSManagedObjectContext

  :returns: Form
  */
  static func creationForm(#context: NSManagedObjectContext) -> Form {
    return Form(templates: OrderedDictionary<String, FieldTemplate>(["Name": nameFormFieldTemplate(context: context)]))
  }

  /**
  createWithForm:context:

  :param: form Form
  :param: context NSManagedObjectContext

  :returns: Preset?
  */
  static func createWithForm(form: Form, context: NSManagedObjectContext) -> Preset? {
    if let name = form.values?["Name"] as? String { return Preset(name: name, context: context) } else { return nil }
  }

}