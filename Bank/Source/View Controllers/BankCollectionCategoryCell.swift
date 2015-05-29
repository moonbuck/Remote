//
//  BankCollectionCategoryCell.swift
//  Remote
//
//  Created by Jason Cardwell on 9/27/14.
//  Copyright (c) 2014 Moondeer Studios. All rights reserved.
//
import Foundation
import UIKit
import MoonKit
import DataModel

final class BankCollectionCategoryCell: BankCollectionCell {

  override class var cellIdentifier: String { return "CategoryCell" }

  var collection: ModelCollection? { didSet { label.text = collection?.name } }

  override var exportItem: JSONValueConvertible? { return collection as? JSONValueConvertible }

  private let label: UILabel = { let view = UILabel(autolayout: true); view.font = Bank.infoFont; return view }()

  /** updateConstraints */
  override func updateConstraints() {

    let identifier = createIdentifier(self, "Internal")
    removeConstraintsWithIdentifier(identifier)

    super.updateConstraints()

    constrain(identifier: identifier,
      indicator--20--label--8--chevron,
      [label.centerY => contentView.centerY,
      indicator.centerY => contentView.centerY,
      indicator.right => contentView.left + (indicatorImage == nil ? 0 : 40)]
    )

    let predicate = NSPredicate(format: "firstItem == %@" +
                                        "AND secondItem == %@ " +
                                        "AND firstAttribute == \(NSLayoutAttribute.Right.rawValue)" +
                                        "AND secondAttribute == \(NSLayoutAttribute.Left.rawValue)" +
                                        "AND relation == \(NSLayoutRelation.Equal.rawValue)", indicator, contentView)
    indicatorConstraint = constraintMatching(predicate)

  }

  /** initializeSubviews */
  private func initializeSubviews() { contentView.addSubview(label) }

  /**
  initWithFrame:

  :param: frame CGRect
  */
  override init(frame: CGRect) { super.init(frame: frame); initializeSubviews() }

  /**
  init:

  :param: aDecoder NSCoder
  */
  required init(coder aDecoder: NSCoder) { super.init(coder: aDecoder); initializeSubviews() }

}
