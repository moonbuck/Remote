//
//  DetailTwoToneSliderCell.swift
//  Remote
//
//  Created by Jason Cardwell on 12/08/14.
//  Copyright (c) 2014 Moondeer Studios. All rights reserved.
//

import Foundation
import UIKit
import MoonKit

class DetailTwoToneSliderCell: DetailCell {

  /**
  initWithStyle:reuseIdentifier:

  - parameter style: UITableViewCellStyle
  - parameter reuseIdentifier: String?
  */
  override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
    super.init(style: style, reuseIdentifier: reuseIdentifier)
    sliderView.addTarget(self, action: "sliderValueDidChange:", forControlEvents: .ValueChanged)
    sliderView.userInteractionEnabled = false
    contentView.addSubview(nameLabel)
    contentView.addSubview(sliderView)
    let format = "|-[name]-[slider]-| :: V:|-[name]-| :: V:|-[slider]-|"
    contentView.constrain(format, views: ["name": nameLabel, "label": infoLabel, "slider": sliderView])
  }

  /**
  sliderValueDidChange:

  - parameter sender: UISlider
  */
  func sliderValueDidChange(sender: UISlider) { valueDidChange?(sender.value) }

  override var infoDataType: DataType { get { return .FloatData(0.0...1.0)} set {} }

  /**
  init:

  - parameter aDecoder: NSCoder
  */
  required init(coder aDecoder: NSCoder) { super.init(coder: aDecoder) }

  /** prepareForReuse */
  override func prepareForReuse() { super.prepareForReuse(); nameLabel.text = nil }

  override var isEditingState: Bool { didSet { sliderView.userInteractionEnabled = isEditingState } }

  override var info: AnyObject? {
    get { return sliderView.value }
    set { sliderView.value = (newValue as? NSNumber)?.floatValue ?? sliderView.minimumValue }
  }

  private let sliderView = TwoToneSlider(type: .Custom, autolayout: true)

  var generatedColorType: TwoToneSlider.GeneratedColorType {
    get { return sliderView.generatedColorType }
    set { sliderView.generatedColorType = newValue }
  }

  var lowerColor: (TwoToneSlider) -> UIColor {
    get { return sliderView.lowerColor }
    set { sliderView.lowerColor = newValue }
  }

  var upperColor: (TwoToneSlider) -> UIColor {
    get { return sliderView.upperColor }
    set { sliderView.upperColor = newValue }
  }

}
