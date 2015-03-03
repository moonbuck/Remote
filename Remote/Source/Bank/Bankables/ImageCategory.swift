//
//  ImageCategory.swift
//  Remote
//
//  Created by Jason Cardwell on 9/27/14.
//  Copyright (c) 2014 Moondeer Studios. All rights reserved.
//

import Foundation
import CoreData
import MoonKit

@objc(ImageCategory)
class ImageCategory: BankableModelCategory {

  override class func itemType() -> BankableModelObject.Type { return Image.self }

  @NSManaged var subcategoriesSet: NSSet?
  @NSManaged var primitiveParentCategory: ImageCategory?
  override var parentCategory: BankItemCategory? {
    get {
      willAccessValueForKey("parentCategory")
      let category = primitiveParentCategory
      didAccessValueForKey("parentCategory")
      return category
    }
    set {
      willChangeValueForKey("parentCategory")
      primitiveParentCategory = newValue as? ImageCategory
      didChangeValueForKey("parentCategory")
    }
  }
  @NSManaged var images: NSSet?

  /**
  imageForPath:context:

  :param: path String
  :param: context NSManagedObjectContext

  :returns: Image?
  */
  class func imageForPath(path: String?, context: NSManagedObjectContext?) -> Image? {
    var image: Image?
    if path != nil && context != nil {
      var components = split(path!){$0 == "/"}
      if components.count > 1 {
        components = components.reverse()
        var categoryName = components.removeLast()
        var category: ImageCategory? = findFirstMatchingPredicate(∀"parentCategory == nil AND name == \"\(categoryName)\"",
                                                          context: context!)
        if category != nil {
          components = components.reverse()
          image = itemForCategory(category!, atPath: "/".join(components)) as? Image
        }
      }
    }
    return image
  }

  override var subcategories: [BankItemCategory] {
    get { return ((subcategoriesSet?.allObjects ?? []) as! [ImageCategory]).sorted{$0.0.title < $0.1.title} }
    set { if let newSubcategories = newValue as? [ImageCategory] { subcategoriesSet = NSSet(array: newSubcategories) } }
  }

  override var items: [BankItemModel] {
    get { return sortedByName((images?.allObjects ?? []) as! [Image]) }
    set { if let newItems = newValue as? [Image] { images = NSSet(array: newItems) } }
  }

  override var previewableItems:   Bool { return true }
  override var editableItems:      Bool { return true }

  /**
  updateWithData:

  :param: data [NSObject:AnyObject]!
  */
  override func updateWithData(data: [NSObject:AnyObject]!) {
    super.updateWithData(data) // sets uuid, name

    // Try importing images
    if let imageData = data["images"] as? NSArray, let moc = managedObjectContext {
      if images == nil { images = NSSet() }
      let mutableImages = mutableSetValueForKey("images")
      mutableImages.addObjectsFromArray(Image.importObjectsFromData(imageData, context: moc))
    }

    // Try importing subcategories
    if let subCategoryData = data["subcategories"] as? NSArray, let moc = managedObjectContext {
      if subcategoriesSet == nil { subcategoriesSet = NSSet() }
      let mutableSubcategories = mutableSetValueForKey("subcategoriesSet")
      mutableSubcategories.addObjectsFromArray(ImageCategory.importObjectsFromData(subCategoryData, context: moc))
    }

  }

  /**
  JSONDictionary

  :returns: MSDictionary!
  */
  override func JSONDictionary() -> MSDictionary {
    let dictionary = super.JSONDictionary()

    if let imageDictionaries = sortedByName(images?.allObjects as? [Image])?.map({$0.JSONDictionary()}) {
      if imageDictionaries.count > 0 {
        apply(imageDictionaries){$0.removeObjectForKey("category")}
        dictionary["images"] = imageDictionaries
      }
    }

    if let subcategoryDictionaries = sortedByName(subcategoriesSet?.allObjects as? [ImageCategory])?.map({$0.JSONDictionary()}) {
      if subcategoryDictionaries.count > 0 {
        dictionary["subcategories"] = subcategoryDictionaries
      }
    }

    return dictionary
  }




}
