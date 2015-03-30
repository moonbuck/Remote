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

  /// A private structure to encapsulate constant class properties
  ////////////////////////////////////////////////////////////////////////////////
  private struct DetailControllerProperties {

    // Fonts
    static let labelFont                  = UIFont(name: "Elysio-Medium", size: 15.0)!
    static let boldLabelFont              = UIFont(name: "Elysio-Bold",   size: 17.0)!
    static let infoFont                   = UIFont(name: "Elysio-Light",  size: 15.0)!
    static let actionFont                 = UIFont(name: "Elysio-RegularItalic", size: 15.0)!

    // Colors
    static let labelColor                 = UIColor(r: 59 , g: 60,  b: 64,  a: 255)!
    static let infoColor                  = UIColor(r: 159, g: 160, b: 164, a: 255)!
    static let actionColor                = UIColor(r: 0,   g: 175, b: 255, a: 255)!
    static let backgroundColor            = UIColor.whiteColor()

    static let defaultRowHeight: CGFloat = 38.0
    static let separatorStyle: UITableViewCellSeparatorStyle = .None
    static let keyboardAppearance: UIKeyboardAppearance = .Dark

    static let titleTextAttributes = [ NSFontAttributeName:            DetailControllerProperties.boldLabelFont,
                                       NSForegroundColorAttributeName: DetailControllerProperties.labelColor ]
  }

  /// Font accessors
  ////////////////////////////////////////////////////////////////////////////////

  class var labelFont                  : UIFont  { return DetailControllerProperties.labelFont     }
  class var boldLabelFont              : UIFont  { return DetailControllerProperties.boldLabelFont }
  class var infoFont                   : UIFont  { return DetailControllerProperties.infoFont      }
  class var actionFont                 : UIFont  { return DetailControllerProperties.actionFont    }

  /// Color accessors
  ////////////////////////////////////////////////////////////////////////////////

  class var labelColor                 : UIColor { return DetailControllerProperties.labelColor      }
  class var infoColor                  : UIColor { return DetailControllerProperties.infoColor       }
  class var actionColor                : UIColor { return DetailControllerProperties.actionColor     }
  class var backgroundColor            : UIColor { return DetailControllerProperties.backgroundColor }

  /// Keyboard
  ////////////////////////////////////////////////////////////////////////////////

  class var keyboardAppearance: UIKeyboardAppearance { return DetailControllerProperties.keyboardAppearance }

  /// Metrics
  ////////////////////////////////////////////////////////////////////////////////

  class var defaultRowHeight: CGFloat { return DetailControllerProperties.defaultRowHeight }

  /// Styles
  ////////////////////////////////////////////////////////////////////////////////

  class var separatorStyle: UITableViewCellSeparatorStyle { return DetailControllerProperties.separatorStyle }

  class var titleTextAttributes: [NSString : NSObject] { return DetailControllerProperties.titleTextAttributes }

  var sections: OrderedDictionary<String, DetailSection> = [:] { didSet { apply(sections.values){$0.controller = self} } }

  let item: Detailable!

  private(set) var didCancel: Bool = false

  private(set) weak var cellDisplayingPicker: DetailButtonCell?

  /**
  init:bundle:

  :param: nibNameOrNil String?
  :param: nibBundleOrNil NSBundle?
  */
//  override init(nibName: String?, bundle: NSBundle?) {
//    super.init(nibName: nibName, bundle: bundle)
//  }

  /**
  initWithStyle:

  :param: style UITableViewStyle
  */
//  override init(style: UITableViewStyle) { super.init(style: style) }

  /**
  initWithCoder:

  :param: aDecoder NSCoder
  */
  required init(coder aDecoder: NSCoder) { item = nil; super.init(coder: aDecoder) }


  /**
  initWithItem:

  :param: item Detailable
  */
  init(item: Detailable) {
    self.item = item
    super.init(style: .Grouped)
    hidesBottomBarWhenPushed = true
  }

  /** loadSections */
  func loadSections() { sections.removeAll(keepCapacity: true) }

  /** loadView */
  override func loadView() {
    tableView = UITableView(frame: UIScreen.mainScreen().bounds, style: .Grouped)
    tableView?.rowHeight = UITableViewAutomaticDimension
    tableView?.estimatedRowHeight = 44.0
    tableView?.sectionHeaderHeight = UITableViewAutomaticDimension
    tableView?.estimatedSectionHeaderHeight = 44.0
    tableView?.sectionFooterHeight = 10.0
    tableView?.separatorStyle = .None
    tableView?.delegate = self
    tableView?.dataSource = self
    DetailCell.registerIdentifiersWithTableView(tableView)
    DetailSectionHeader.registerIdentifiersWithTableView(tableView)
    navigationItem.rightBarButtonItem = editButtonItem()
  }


  /** updateDisplay */
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
  viewWillAppear:

  :param: animated Bool
  */
  override func viewWillAppear(animated: Bool) { super.viewWillAppear(animated); updateDisplay() }

  /**
  setEditing:animated:

  :param: editing Bool
  :param: animated Bool
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

  /** cancel */
  func cancel() {
    (item as? Editable)?.rollback()
    didCancel = true
    setEditing(false, animated: true)
    updateDisplay()
  }

  /** edit */
  func edit() { if !editing { setEditing(true, animated: true) } }

  /** save */
  func save() { (item as? Editable)?.save(); setEditing(false, animated: true) }

  /**
  subscript:

  :param: indexPath NSIndexPath

  :returns: DetailRow?
  */
  subscript(indexPath: NSIndexPath) -> DetailRow? { return self[indexPath.row, indexPath.section] }

  /**
  subscript:

  :param: section Int

  :returns: DetailSection?
  */
  subscript(section: Int) -> DetailSection? { return section < sections.count ? sections.values[section] : nil }

  /**
  reloadSection:

  :param: section Int
  :param: animation UITableViewRowAnimation = .Automatic
  */
  func reloadSection(section: Int, withRowAnimation animation: UITableViewRowAnimation = .Automatic) {
    tableView.beginUpdates()
    // TODO: reload individual `DetailSection` objects
    tableView.reloadSections(NSIndexSet(index: section), withRowAnimation: animation)
    tableView.endUpdates()
  }

  /**
  reloadSection:

  :param: section DetailSection
  :param: animation UITableViewRowAnimation = .Automatic
  */
  func reloadSection(section: DetailSection, withRowAnimation animation: UITableViewRowAnimation = .Automatic) {
    reloadSection(section.section, withRowAnimation: animation)
  }

  /**
  subscript:section:

  :param: row Int
  :param: section Int

  :returns: DetailRow?
  */
  subscript(row: Int, section: Int) -> DetailRow? { return self[section]?[row] }

  /**
  reloadRowAtIndexPath:withRowAnimation:

  :param: indexPath NSIndexPath
  :param: animation UITableViewRowAnimation = .Automatic
  */
  func reloadRowAtIndexPath(indexPath: NSIndexPath, withRowAnimation animation: UITableViewRowAnimation = .Automatic) {
    reloadRowsAtIndexPaths([indexPath], withRowAnimation: animation)
  }

  /**
  reloadRowsAtIndexPaths:animated:

  :param: indexPaths [NSIndexPath]
  :param: animation UITableViewRowAnimation = .Automatic
  */
  func reloadRowsAtIndexPaths(indexPaths: [NSIndexPath], withRowAnimation animation: UITableViewRowAnimation = .Automatic) {
    tableView.beginUpdates()
    tableView.reloadRowsAtIndexPaths(indexPaths, withRowAnimation: animation)
    tableView.endUpdates()
  }

  /**
  removeRowAtIndexPath:withRowAnimation:

  :param: indexPath NSIndexPath
  :param: animation UITableViewRowAnimation = .Automatic
  */
  func removeRowAtIndexPath(indexPath: NSIndexPath, withRowAnimation animation: UITableViewRowAnimation = .Automatic) {
    tableView.beginUpdates()
    tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: animation)
    tableView.endUpdates()
  }

  /**
  insertRowAtIndexPath:withRowAnimation:

  :param: indexPath NSIndexPath
  :param: animation UITableViewRowAnimation = .Automatic
  */
  func insertRowAtIndexPath(indexPath: NSIndexPath, withRowAnimation animation: UITableViewRowAnimation = .Automatic) {
    tableView.beginUpdates()
    tableView.insertRowsAtIndexPaths([indexPath], withRowAnimation: animation)
    tableView.endUpdates()
  }

  /** configureVisibleCells */
  func configureVisibleCells() {
    if let visibleIndexPaths = tableView.indexPathsForVisibleRows() as? [NSIndexPath] {
      configureCellsAtIndexPaths(visibleIndexPaths)
    }
  }

  /**
  configureCellsAtIndexPaths:

  :param: indexPaths [NSIndexPath]
  */
  func configureCellsAtIndexPaths(indexPaths: [NSIndexPath]) {
    applyToRowsAtIndexPaths(indexPaths) {
      if let cell = self.tableView.cellForRowAtIndexPath($0.indexPath!) as? DetailCell {
        $0.configureCell(cell)
      }
    }
  }

  /**
  applyToRowsAtIndexPaths:block:

  :param: indexPaths [NSIndexPath]
  :param: block (DetailRow) -> Void
  */
  func applyToRowsAtIndexPaths(indexPaths: [NSIndexPath], block: (DetailRow) -> Void) {
    if let visibleIndexPaths = tableView.indexPathsForVisibleRows() as? [NSIndexPath] {
      apply(compressed((indexPaths ∩ visibleIndexPaths).map({self[$0]})), block)
    }
  }

  /**
  dequeueCellForIndexPath:

  :param: indexPath NSIndexPath

  :returns: DetailCell?
  */
  func dequeueCellForIndexPath(indexPath: NSIndexPath) -> DetailCell? {

    var cell: DetailCell?

    if let identifier = self[indexPath]?.identifier {

      cell = tableView.dequeueReusableCellWithIdentifier(identifier.rawValue, forIndexPath: indexPath) as? DetailCell

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

    } // end if

    return cell
  }

}

/// MARK: - UITableViewDelegate
////////////////////////////////////////////////////////////////////////////////
extension DetailController: UITableViewDelegate {

  /**
  tableView:editingStyleForRowAtIndexPath:

  :param: tableView UITableView
  :param: indexPath NSIndexPath

  :returns: UITableViewCellEditingStyle
  */
  override func         tableView(tableView: UITableView,
    editingStyleForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCellEditingStyle
  {
    return self[indexPath]?.editingStyle ?? .None
  }

  /**
  tableView:willDisplayCell:forRowAtIndexPath:

  :param: tableView UITableView
  :param: cell UITableViewCell
  :param: indexPath NSIndexPath
  */
  override func tableView(tableView: UITableView,
          willDisplayCell cell: UITableViewCell,
        forRowAtIndexPath indexPath: NSIndexPath)
  {
    (cell as? DetailCell)?.isEditingState = editing
  }

  /**
  tableView:didSelectRowAtIndexPath:

  :param: tableView UITableView
  :param: indexPath NSIndexPath
  */
  override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
    self[indexPath]?.select?()
    sqrt(4.0)
  }

  /**
  tableView:heightForHeaderInSection:

  :param: tableView UITableView
  :param: section Int

  :returns: CGFloat
  */
  // override func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
  //   return sections[section] is FilteringDetailSection ? 64.0 : 44.0
  // }

}

/// MARK: - UITableViewDataSource
////////////////////////////////////////////////////////////////////////////////
extension DetailController: UITableViewDataSource {

  /**
  tableView:cellForRowAtIndexPath:

  :param: tableView UITableView
  :param: indexPath NSIndexPath

  :returns: UITableViewCell
  */
  override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
    let cell = dequeueCellForIndexPath(indexPath)
    precondition(cell != nil, "we should have been able to dequeue a valid cell")
    self[indexPath]?.configureCell(cell!)
    return cell!
  }

  /**
  numberOfSectionsInTableView:

  :param: tableView UITableView

  :returns: Int
  */
  override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
    return sections.count
  }


  /**
  tableView:numberOfRowsInSection:

  :param: tableView UITableView
  :param: section Int

  :returns: Int
  */
  override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return self[section]?.count ?? 0
  }

  /**
  tableView:viewForHeaderInSection:

  :param: tableView UITableView
  :param: section Int

  :returns: UIView?
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

  :param: tableView UITableView
  :param: indexPath NSIndexPath

  :returns: Bool
  */
  override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool { return true }

  /**
  tableView:commitEditingStyle:forRowAtIndexPath:

  :param: tableView UITableView
  :param: editingStyle UITableViewCellEditingStyle
  :param: indexPath NSIndexPath
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

  :param: tableView UITableView
  :param: indexPath NSIndexPath

  :returns: [AnyObject]?
  */
  override func tableView(tableView: UITableView, editActionsForRowAtIndexPath indexPath: NSIndexPath) -> [AnyObject]? {
    return self[indexPath]?.editActions
  }

}

/// MARK: - Utility functions
////////////////////////////////////////////////////////////////////////////////

extension DetailController {

  /**
  pushController:

  :param: controller UIViewController
  */
  func pushController(controller: UIViewController) {
    (UIApplication.sharedApplication().keyWindow?.rootViewController as? UINavigationController)?
      .pushViewController(controller, animated: true)
  }

}