//
//  DetailController.swift
//  Remote
//
//  Created by Jason Cardwell on 9/26/14.
//  Copyright (c) 2014 Moondeer Studios. All rights reserved.
//

import Foundation
import UIKit
import MoonKit
import DataModel

class DetailController: UITableViewController {

  // MARK: - Properties

  var sections: OrderedDictionary<String, DetailSection> = [:] { didSet { apply(sections.values){$0.controller = self} } }

  private(set) var item: Detailable!

  private(set) var didCancel: Bool = false

  private(set) weak var cellDisplayingPicker: DetailButtonCell?

  // MARK: - Initializers

  /**
  init:bundle:

  - parameter nibNameOrNil: String?
  - parameter nibBundleOrNil: NSBundle?
  */
  override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: NSBundle?) {
    super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
  }

  /**
  initWithCoder:

  - parameter aDecoder: NSCoder
  */
  required init(coder aDecoder: NSCoder) { fatalError("must use init(item:)") }

  /**
  initWithItem:

  - parameter item: Detailable
  */
  init(item: Detailable) { super.init(style: .Grouped); self.item = item; hidesBottomBarWhenPushed = true }

  // MARK: - Loading

  /** loadSections */
  func loadSections() { sections.removeAll(true) }

  /** loadView */
  override func loadView() {
    tableView = UITableView(frame: UIScreen.mainScreen().bounds, style: .Grouped)
    tableView.estimatedRowHeight = 44.0
    tableView.rowHeight = UITableViewAutomaticDimension
    tableView.sectionHeaderHeight = UITableViewAutomaticDimension
    tableView.estimatedSectionHeaderHeight = 44.0
    tableView.sectionFooterHeight = 10.0
    tableView.separatorStyle = .None
    tableView.delegate = self
    tableView.dataSource = self
    DetailCell.registerIdentifiersWithTableView(tableView)
    DetailSectionHeader.registerIdentifiersWithTableView(tableView)
    navigationItem.rightBarButtonItem = editButtonItem()
  }

  // MARK: - Updating


  /** Configures right bar button item, resets `didCancel` flag, configures visible cells, loads sections and reloads data */
  func updateDisplay() {
    if let editableItem = item as? Editable {
      navigationItem.rightBarButtonItem?.enabled = editableItem.editable
    } else {
      navigationItem.rightBarButtonItem?.enabled = false
    }
    didCancel = false
    configureVisibleCells()
    loadSections()
    tableView.reloadData()
 }

  /**
  Updates display

  - parameter animated: Bool
  */
  override func viewWillAppear(animated: Bool) { super.viewWillAppear(animated); updateDisplay() }

  /**
  Invokes table view section reload wrapped inside `beginUpdates` and `endUpdates`

  - parameter section: Int
  - parameter animation: UITableViewRowAnimation = .Automatic
  */
  func reloadSection(section: Int, withRowAnimation animation: UITableViewRowAnimation = .Automatic) {
    tableView.beginUpdates()
    tableView.reloadSections(NSIndexSet(index: section), withRowAnimation: animation)
    tableView.endUpdates()
  }

  /**
  Invokes table view section reload wrapped inside `beginUpdates` and `endUpdates`

  - parameter section: DetailSection
  - parameter animation: UITableViewRowAnimation = .Automatic
  */
  func reloadSection(section: DetailSection, withRowAnimation animation: UITableViewRowAnimation = .Automatic) {
    reloadSection(section.section, withRowAnimation: animation)
  }

  /**
  Calls the table view's `reloadRowAtIndexPath` method wrapped inside `beginUpdates` and `endUpdates`

  - parameter indexPath: NSIndexPath
  - parameter animation: UITableViewRowAnimation = .Automatic
  */
  func reloadRowAtIndexPath(indexPath: NSIndexPath, withRowAnimation animation: UITableViewRowAnimation = .Automatic) {
    reloadRowsAtIndexPaths([indexPath], withRowAnimation: animation)
  }

  /**
  Calls the table view's `reloadRowsAtIndexPaths` method wrapped inside `beginUpdates` and `endUpdates`

  - parameter indexPaths: [NSIndexPath]
  - parameter animation: UITableViewRowAnimation = .Automatic
  */
  func reloadRowsAtIndexPaths(indexPaths: [NSIndexPath], withRowAnimation animation: UITableViewRowAnimation = .Automatic) {
    tableView.beginUpdates()
    tableView.reloadRowsAtIndexPaths(indexPaths, withRowAnimation: animation)
    tableView.endUpdates()
  }

  /**
  Calls the table view's `removeRowAtIndexPath` method wrapped inside `beginUpdates` and `endUpdates`

  - parameter indexPath: NSIndexPath
  - parameter animation: UITableViewRowAnimation = .Automatic
  */
  func removeRowAtIndexPath(indexPath: NSIndexPath, withRowAnimation animation: UITableViewRowAnimation = .Automatic) {
    tableView.beginUpdates()
    tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: animation)
    tableView.endUpdates()
  }

  /**
  Calls the table view's `insertRowAtIndexPath` method wrapped inside `beginUpdates` and `endUpdates`

  - parameter indexPath: NSIndexPath
  - parameter animation: UITableViewRowAnimation = .Automatic
  */
  func insertRowAtIndexPath(indexPath: NSIndexPath, withRowAnimation animation: UITableViewRowAnimation = .Automatic) {
    tableView.beginUpdates()
    tableView.insertRowsAtIndexPaths([indexPath], withRowAnimation: animation)
    tableView.endUpdates()
  }

  /** Invokes `configureCell` for each `DetailRow` associated with a visible cell */
  func configureVisibleCells() {
    if let visibleIndexPaths = tableView.indexPathsForVisibleRows {
      configureCellsAtIndexPaths(visibleIndexPaths)
    }
  }

  /**
  Invokes `configureCell` for each `DetailRow` associated with the index paths specified

  - parameter indexPaths: [NSIndexPath]
  */
  func configureCellsAtIndexPaths(indexPaths: [NSIndexPath]) {
    applyToRowsAtIndexPaths(indexPaths) {
      if let cell = self.tableView.cellForRowAtIndexPath($0.indexPath!) as? DetailCell {
        $0.configureCell(cell)
      }
    }
  }

  /**
  Performs the specified block for each `DetailRow` retrieved via the specified index paths

  - parameter indexPaths: [NSIndexPath]
  - parameter block: (DetailRow) -> Void
  */
  func applyToRowsAtIndexPaths(indexPaths: [NSIndexPath], block: (DetailRow) -> Void) {
    if let visibleIndexPaths = tableView.indexPathsForVisibleRows {
      apply(compressed((indexPaths ∩ visibleIndexPaths).map({self[$0]})), block)
    }
  }

  // MARK: - Navigation bar actions

  /**
  Updates `navigationItem` and the calls `super`'s implementation, if current value for `editing` differs from parameter

  - parameter editing: Bool
  - parameter animated: Bool
  */
  override func setEditing(editing: Bool, animated: Bool) {
    if self.editing != editing {
      navigationItem.leftBarButtonItem = editing
                                           ? UIBarButtonItem(barButtonSystemItem: .Cancel, target: self, action: "cancel")
                                           : nil
      navigationItem.rightBarButtonItem?.title = editing ? "Save" : "Edit"
      navigationItem.rightBarButtonItem?.action = editing ? "save" : "edit"
      super.setEditing(editing, animated: animated)
    }
  }

  /** Invokes `rollback` on `item`, sets `didCancel` flag to true, sets `editing` to false and refresh display */
  func cancel() {
    (item as? Editable)?.rollback()
    didCancel = true
    setEditing(false, animated: true)
    updateDisplay()
  }

  /** edit */
  func edit() { if !editing { setEditing(true, animated: true) } }

  /** Invokes `save` on `item` if the item is `Editable`. Afterwards, `editing` is set to `false` */
  func save() { (item as? Editable)?.save(); setEditing(false, animated: true) }

  // MARK: - Subscripting

  /**
  Accessor for `DetailRow` objects by `NSIndexPath`

  - parameter indexPath: NSIndexPath

  - returns: DetailRow?
  */
  subscript(indexPath: NSIndexPath) -> DetailRow? { return self[indexPath.row, indexPath.section] }

  /**
  Accessor for `DetailSection` objects by index

  - parameter section: Int

  - returns: DetailSection?
  */
  subscript(section: Int) -> DetailSection? { return section < sections.count ? sections.values[section] : nil }

  /**
  Accessor for the `DetailRow` identified by row and section

  - parameter row: Int
  - parameter section: Int

  - returns: DetailRow?
  */
  subscript(row: Int, section: Int) -> DetailRow? { return self[section]?[row] }

}

/// MARK: - UITableViewDelegate

extension DetailController {

  /**
  tableView:editingStyleForRowAtIndexPath:

  - parameter tableView: UITableView
  - parameter indexPath: NSIndexPath

  - returns: UITableViewCellEditingStyle
  */
  override func         tableView(tableView: UITableView,
    editingStyleForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCellEditingStyle
  {
    return self[indexPath]?.editingStyle ?? .None
  }

  /**
  tableView:willDisplayCell:forRowAtIndexPath:

  - parameter tableView: UITableView
  - parameter cell: UITableViewCell
  - parameter indexPath: NSIndexPath
  */
  override func tableView(tableView: UITableView,
          willDisplayCell cell: UITableViewCell,
        forRowAtIndexPath indexPath: NSIndexPath)
  {
    (cell as? DetailCell)?.isEditingState = editing
  }

  /**
  tableView:didSelectRowAtIndexPath:

  - parameter tableView: UITableView
  - parameter indexPath: NSIndexPath
  */
  override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
    self[indexPath]?.select?()
  }

  /**
  tableView:heightForHeaderInSection:

  - parameter tableView: UITableView
  - parameter section: Int

  - returns: CGFloat
  */
  // override func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
  //   return sections[section] is FilteringDetailSection ? 64.0 : 44.0
  // }

}

/// MARK: - UITableViewDataSource

extension DetailController {

  /**
  tableView:cellForRowAtIndexPath:

  - parameter tableView: UITableView
  - parameter indexPath: NSIndexPath

  - returns: UITableViewCell
  */
  override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {

    let identifier = self[indexPath]!.identifier

    let cell = tableView.dequeueReusableCellWithIdentifier(identifier.rawValue, forIndexPath: indexPath) as! DetailCell

    // Set picker related handlers if the cell is a button cell
    if let buttonCell = cell as? DetailButtonCell {

      // Set handler for showing picker row for this button cell
      buttonCell.showPickerRow = {

        // Check if we are already showing a picker row
        if let cell = self.cellDisplayingPicker {

          // Remove existing picker row
          cell.hidePickerView()

          // Return false if this handler was invoked by the same cell
          if cell === $0 { return false }

        }

        // Ensure we actually have a picker row to insert
        if $0.detailPickerRow == nil { return false }

        if let cellIndexPath = self.tableView.indexPathForCell($0) {

          // Create an index path for the row after the button cell's row
          let pickerPath = NSIndexPath(forRow: cellIndexPath.row + 1, inSection: cellIndexPath.section)


          // Insert row into our section
          self.sections.values[pickerPath.section].insertRow($0.detailPickerRow!, atIndex: pickerPath.row, forKey: "Picker")

          self.insertRowAtIndexPath(pickerPath)

          // Scroll to the inserted row
          self.tableView.scrollToRowAtIndexPath(pickerPath, atScrollPosition: .Middle, animated: true)

          // Update reference to cell displaying picker row
          self.cellDisplayingPicker = $0

          return true
        }

        return false
      }

      // Set handler for hiding picker row for this button cell
      buttonCell.hidePickerRow = {

        // Check if the cell invoking this handler is actually the cell whose picker we are showing
        if self.cellDisplayingPicker !== $0 { return false }

        if let cellIndexPath = self.tableView.indexPathForCell($0) {

          // Create an index path for the row after the button cell's row
          let pickerPath = NSIndexPath(forRow: cellIndexPath.row + 1, inSection: cellIndexPath.section)

          if !(self[pickerPath] is DetailPickerRow) { return false }

          // Remove the row from our section
          self[pickerPath.section]?.removeRowAtIndex(pickerPath.row)

          self.removeRowAtIndexPath(pickerPath)

          // Update reference to cell displaying picker row
          self.cellDisplayingPicker = nil

          return true
        }

        return false
      }

    } // end if

    self[indexPath]?.configureCell(cell)
    return cell
  }

  /**
  numberOfSectionsInTableView:

  - parameter tableView: UITableView

  - returns: Int
  */
  override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
    return sections.count
  }


  /**
  tableView:numberOfRowsInSection:

  - parameter tableView: UITableView
  - parameter section: Int

  - returns: Int
  */
  override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return self[section]?.count ?? 0
  }

  /**
  tableView:viewForHeaderInSection:

  - parameter tableView: UITableView
  - parameter section: Int

  - returns: UIView?
  */
  override func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
    let detailSection = sections.values[section]
    let identifier = detailSection.identifier.rawValue
    let header = tableView.dequeueReusableHeaderFooterViewWithIdentifier(identifier) as! DetailSectionHeader
    detailSection.configureHeader(header)
    return header
  }

  /**
  tableView:canEditRowAtIndexPath:

  - parameter tableView: UITableView
  - parameter indexPath: NSIndexPath

  - returns: Bool
  */
  override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool { return true }

  /**
  tableView:commitEditingStyle:forRowAtIndexPath:

  - parameter tableView: UITableView
  - parameter editingStyle: UITableViewCellEditingStyle
  - parameter indexPath: NSIndexPath
  */
  override func tableView(tableView: UITableView,
       commitEditingStyle editingStyle: UITableViewCellEditingStyle,
        forRowAtIndexPath indexPath: NSIndexPath)
  {
    if editingStyle == .Delete {
      if self[indexPath]?.delete?() != nil {
        tableView.beginUpdates()
        if self[indexPath]?.deleteRemovesRow == true {
          removeRowAtIndexPath(indexPath)
          reloadSection(indexPath.section)
        }
        tableView.endUpdates()
      }
    }
  }

  /**
  tableView:editActionsForRowAtIndexPath:

  - parameter tableView: UITableView
  - parameter indexPath: NSIndexPath

  - returns: [AnyObject]?
  */
  override func tableView(tableView: UITableView, editActionsForRowAtIndexPath indexPath: NSIndexPath) -> [UITableViewRowAction]? {
    return self[indexPath]?.editActions
  }

}

/// MARK: - Utility functions

extension DetailController {

  /**
  Attempts to have navigation controller push the specified view controller

  - parameter controller: UIViewController
  */
  func pushController(controller: UIViewController) {
    (UIApplication.sharedApplication().keyWindow?.rootViewController as? UINavigationController)?
      .pushViewController(controller, animated: true)
  }

}
