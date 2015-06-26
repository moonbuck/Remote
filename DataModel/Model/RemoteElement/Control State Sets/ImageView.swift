//
//  ImageView.swift
//  Remote
//
//  Created by Jason Cardwell on 10/3/14.
//  Copyright (c) 2014 Moondeer Studios. All rights reserved.
//

import Foundation
import CoreData
import MoonKit

@objc(ImageView)
public final class ImageView: ModelObject, NSCopying {

  @NSManaged public var color: UIColor?
  @NSManaged public var image: Image?
  @NSManaged public var alpha: NSNumber?

  @NSManaged public var buttonIcon: Button?
  @NSManaged public var buttonImage: Button?
  @NSManaged public var imageSetDisabled: ControlStateImageSet?
  @NSManaged public var imageSetDisabledSelected: ControlStateImageSet?
  @NSManaged public var imageSetHighlighted: ControlStateImageSet?
  @NSManaged public var imageSetHighlightedDisabled: ControlStateImageSet?
  @NSManaged public var imageSetHighlightedSelected: ControlStateImageSet?
  @NSManaged public var imageSetNormal: ControlStateImageSet?
  @NSManaged public var imageSetSelected: ControlStateImageSet?
  @NSManaged public var imageSetSelectedHighlightedDisabled: ControlStateImageSet?

  public func copyWithZone(zone: NSZone) -> AnyObject {
    let copiedImageView = ImageView(context: managedObjectContext)
    copiedImageView.color = color
    copiedImageView.image = image
    copiedImageView.alpha = alpha
    return copiedImageView
  }
  public var rawImage: UIImage? { return image?.image }

  /**
  imageWithColor:

  - parameter color: UIColor?

  - returns: UIImage?
  */
  public func imageWithColor(color: UIColor?) -> UIImage? {
    if let img = rawImage { return color == nil ? img : UIImage(fromAlphaOfImage: img, color: color) } else { return nil }
  }

  public var colorImage: UIImage? { return imageWithColor(color) }

  /**
  initWithImage:

  - parameter image: Image
  */
  public init(image: Image) {
    super.init(context: image.managedObjectContext)
    self.image = image
  }

  public override init(context: NSManagedObjectContext?) {
    super.init(context: context)
  }

  required public init?(data: ObjectJSONValue, context: NSManagedObjectContext) {
    super.init(data: data, context: context)
  }

  /**
  updateWithData:

  - parameter data: ObjectJSONValue
  */
  override public func updateWithData(data: ObjectJSONValue) {
    super.updateWithData(data)

    updateRelationshipFromData(data, forAttribute: "image")
    color = UIColor(data["color"])
    alpha = Float(data["alpha"])

  }

  override public var description: String {
    var result = super.description
    result += "\n\timage = \(String(image?.index))"
    result += "\n\tcolor = \(String(color?.string))"
    result += "\n\talpha = \(String(alpha))"
    return result
  }

  override public var jsonValue: JSONValue {
    var obj = ObjectJSONValue(super.jsonValue)!
    obj["color"] = color?.jsonValue
    obj["image.index"] = image?.index.jsonValue
    obj["alpha"] = alpha?.jsonValue
    return obj.jsonValue
  }

}

/**
`Equatable` support for `ImageView`

- parameter lhs: ImageView
- parameter rhs: ImageView

- returns: Bool
*/
public func ==(lhs: ImageView, rhs: ImageView) -> Bool { return lhs.isEqual(rhs) }

