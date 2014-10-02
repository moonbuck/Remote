//
//  BankCollectionController.swift
//  Remote
//
//  Created by Jason Cardwell on 9/18/13.
//  Copyright (c) 2013 Moondeer Studios. All rights reserved.
//

import Foundation
import UIKit
import MoonKit

var msLogLevel = LOG_LEVEL_DEBUG

private let ListSegmentImage           = UIImage(named:"1073-grid-1") // 1073-grid-1399-list1
private let ThumbnailSegmentImage      = UIImage(named:"1076-grid-4") // 1076-grid-4822-photo-2
private let IndicatorImage             = UIImage(named:"1040-checkmark")
private let IndicatorImageSelected     = UIImage(named:"1040-checkmark-selected")
private let TextFieldTextColor         = UIColor(RGBAHexString:"#9FA0A4FF")
private let CellIdentifier             = "Cell"
private let HeaderIdentifier           = "Header"

@objc(BankCollectionController)
class BankCollectionController: UICollectionViewController, BankController {

  let collectionItemsController: NSFetchedResultsController?
  let collectionItemClass: BankableModelObject.Type
  var collectionItems: [BankableModelObject]?

  private var updatesBlock: NSBlockOperation?
  private var hiddenSections = [Int]()

  private lazy var zoomView: BankCollectionZoom? = BankCollectionZoom(frame: self.view.bounds, delegate: self)

  private var exportAlertAction: UIAlertAction?
  private var existingFiles:     [String]! {
    didSet {
      if let files = existingFiles {
        let filesString = "\n\t".join(files)
        MSLogDebug("existing json files in documents directory:\n\t\(filesString)")
      }
    }
  }

  private var layout: BankCollectionLayout { return collectionViewLayout as BankCollectionLayout }

  private lazy var exportSelection = [BankableModelObject]()

  private var exportSelectionMode: Bool = false {
    didSet {

      // Create some variables to hold values for common actions to perform
      var rightBarButtonItems: [UIBarButtonItem]
      var cellIndicatorImage: UIImage?

      // Determine if we are entering or leaving export selection mode
      if exportSelectionMode {

        exportSelection.removeAll(keepCapacity: false)  // If entering, make sure our export items collection is empty

        // And, make sure no cells are selected
        if let indexPaths = collectionView!.indexPathsForSelectedItems() as? [NSIndexPath] {
          for indexPath in indexPaths { collectionView!.deselectItemAtIndexPath(indexPath, animated: true) }
        }

        // Set right bar button items
        rightBarButtonItems = [ UIBarButtonItem(title: "Export", style: .Done, target: self, action: "confirmExport:"),
                                UIBarButtonItem(title: "Select All", style: .Plain, target: self, action: "selectAll:") ]


        cellIndicatorImage = IndicatorImage              // Set indicator image


      } else {
        exportAlertAction = nil  // Make sure we don't leave a dangling alert action
        rightBarButtonItems = [ UIBarButtonItem(barButtonSystemItem: .Done, target: self, action: "dismiss:") ]

      }

      collectionView!.allowsMultipleSelection = exportSelectionMode  // Update selection mode

      navigationItem.rightBarButtonItems = rightBarButtonItems  // Update right bar button items

      // Update visible cells
      collectionView?.setValue(cellIndicatorImage, forKeyPath: "visibleCells.indicatorImage")

    }
  }

  private var useListView = true

  /**
  initWithItemClass:

  :param: collectionItemClass BankableModel.Type
  */
  init(itemClass: BankableModelObject.Type) {
    collectionItemClass = itemClass
    super.init(collectionViewLayout: BankCollectionLayout())
    collectionItemsController = collectionItemClass.allItems()
    collectionItemsController?.delegate = self
    if !collectionItemClass.isCategorized() { layout.includeSectionHeaders = false }
  }

  /**
  initWithItems:

  :param: items NSFetchedResultsController
  */
//  init(controller: NSFetchedResultsController) {
//    collectionItemClass = NSClassFromString(controller.fetchRequest.entity.managedObjectClassName) as BankableModelObject.Type
//    super.init(collectionViewLayout: BankCollectionLayout())
//    collectionItemsController = controller
//    collectionItemsController?.delegate = self
//    if !collectionItemClass.isCategorized() { layout.includeSectionHeaders = false }
//  }

  /**
  initWithItems:

  :param: items [BankableModelObject]
  */
  init(items: [BankableModelObject]) {
    collectionItemClass = items[0].dynamicType.self
    super.init(collectionViewLayout: BankCollectionLayout())
    collectionItems = items
    layout.includeSectionHeaders = false
  }

  /**
  init:

  :param: aDecoder NSCoder
  */
  required init(coder aDecoder: NSCoder) {
    let collectionItemClassName = aDecoder.decodeObjectForKey("collectionItemClass") as String
    collectionItemClass = NSClassFromString(collectionItemClassName) as BankableModelObject.Type
    collectionItemsController = collectionItemClass.allItems()
    super.init(coder: aDecoder)
    collectionItemsController?.delegate = self
    if !collectionItemClass.isCategorized() { layout.includeSectionHeaders = false }
  }

  /**
  didMoveToParentViewController:

  :param: parent UIViewController?
  */
  override func didMoveToParentViewController(parent: UIViewController?) {
    super.didMoveToParentViewController(parent)
    if parent != nil { layout.includeSectionHeaders = false }
  }

  /**
  loadView
  */
  override func loadView() {

    if collectionItems != nil { title = collectionItems![0].category.name }
    else { title = collectionItemClass.directoryLabel() }

    collectionView = { [unowned self] in

      // Create the collection layout
      self.layout.viewingMode = .List

      // Create the collection view
      let collectionView = UICollectionView(frame: UIScreen.mainScreen().bounds, collectionViewLayout: self.layout)
      collectionView.backgroundColor = UIColor.whiteColor()

      // Register header and cell classes
      collectionView.registerClass(BankCollectionCell.self, forCellWithReuseIdentifier: CellIdentifier)
      collectionView.registerClass(BankCollectionHeader.self,
        forSupplementaryViewOfKind: UICollectionElementKindSectionHeader,
               withReuseIdentifier: HeaderIdentifier)
      return collectionView

    }()


    toolbarItems = {[unowned self] in

      var items = Bank.toolbarItemsForController(self)

      if self.collectionItemClass.isThumbnailable() {
        // Create the toolbar items
        let displayOptions = UISegmentedControl(items: [ListSegmentImage, ThumbnailSegmentImage])
        displayOptions.selectedSegmentIndex = 0
        displayOptions.addTarget(self, action: "segmentedControlValueDidChange:", forControlEvents: .ValueChanged)

        let displayOptionsItem = UIBarButtonItem(customView: displayOptions)

        items.insert(UIBarButtonItem.flexibleSpace(), atIndex: 4)
        items.insert(displayOptionsItem, atIndex: 4)
      }

      return items
      }()

  }

  deinit { view.removeFromSuperview() }

  /**
  viewWillAppear:

  :param: animated Bool
  */
  override func viewWillAppear(animated: Bool) {
    super.viewWillAppear(animated)
    navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .Done, target: self, action: "dismiss:")

    // ???: Should we reload data here?
    // collectionView?.reloadData()
  }

  /**
  updateViewConstraints
  */
  override func updateViewConstraints() {
    super.updateViewConstraints()

    let identifier = "Internal"

    if view.constraintsWithIdentifier(identifier).count == 0 && zoomView != nil && zoomView!.superview === view {
      view.constrainWithFormat("zoom.center = self.center", views: ["zoom": zoomView!], identifier: identifier)
    }

  }


  ////////////////////////////////////////////////////////////////////////////////
  /// MARK: - Exporting items
  ////////////////////////////////////////////////////////////////////////////////


  /**
  refreshExistingFiles
  */
  private func refreshExistingFiles() {
    let attr = dispatch_queue_attr_make_with_qos_class(DISPATCH_QUEUE_CONCURRENT, QOS_CLASS_BACKGROUND, -1)
    let queue = dispatch_queue_create("com.moondeerstudios.background", attr)

    // Create closure since sticking this directly in the dispatch block crashes compiler
    let updateFiles = {[unowned self] (files: [String]) -> Void in self.existingFiles = files }

    dispatch_async(queue) {
      var directoryContents = MoonFunctions.documentsDirectoryContents()
                              .filter{$0.hasSuffix(".json")}
                                .map{$0[0 ..< ($0.length - 5)]}
      dispatch_async(dispatch_get_main_queue(), {updateFiles(directoryContents)})
    }
  }

  /**
  confirmExport:

  :param: sender AnyObject
  */
  func confirmExport(sender: AnyObject?) {

    var alert: UIAlertController

    // Check if we actually have any items selected for export
    if exportSelection.count > 0 {

      // Refresh our list of existing file names for checking during file export
      refreshExistingFiles()

      // Create the controller with export title and filename message
      alert = UIAlertController(title:          "Export Selection",
                                message:        "Enter a name for the exported file",
                                preferredStyle: .Alert)

      // Add the text field
      alert.addTextFieldWithConfigurationHandler{ [unowned self] in
        $0.font = UIFont.preferredFontForTextStyle(UIFontTextStyleCaption1)
        $0.textColor = TextFieldTextColor
        $0.delegate = self
      }

      // Add the cancel button
      alert.addAction(
        UIAlertAction(title: "Cancel", style: .Cancel) { [unowned self] (action) in
          self.exportSelectionMode = false
          self.dismissViewControllerAnimated(true, completion: nil)
        })

      // Create the export action
      exportAlertAction = UIAlertAction(title: "Export", style: .Default){ [unowned self, alert] (action) in
        let text = (alert.textFields as [UITextField])[0].text
        precondition(text.length > 0 && text ∉ self.existingFiles, "text field should not be empty or match an existing file")
        let pathToFile = MoonFunctions.documentsPathToFile(text + ".json")
        self.exportSelectionToFile(pathToFile!)
        self.exportSelectionMode = false
        self.dismissViewControllerAnimated(true, completion: nil)
      }

      alert.addAction(exportAlertAction!)  // Add the action to the controller

    }

    // If not, let the user know our dilemma
    else {

      // Create the controller with export title and error message
      alert = UIAlertController(title:          "Export Selection",
                                message:        "No items have been selected, what do you suggest I export…hummmn?",
                                preferredStyle: .ActionSheet)

      // Add a button to dismiss
      alert.addAction(
        UIAlertAction(title: "Alright", style: .Default) { [unowned self] (action) in
          self.dismissViewControllerAnimated(true, completion: nil)
        })

    }

    presentViewController(alert, animated: true, completion: nil)  // Present the controller

  }

  /**
  exportSelectionToFile:

  :param: file String
  */
  private func exportSelectionToFile(file: String) { (exportSelection as NSArray).JSONString.writeToFile(file) }

  /**
  exportBankObject:

  :param: sender AnyObject?
  */
  func exportBankObjects() { exportSelectionMode = !exportSelectionMode }


  ////////////////////////////////////////////////////////////////////////////////
  /// MARK: - Actions
  ////////////////////////////////////////////////////////////////////////////////

   /**
  deleteItem:

  :param: item BankableModelObject
  */
  func deleteItem(item: BankableModelObject) { if item.editable { item.managedObjectContext.deleteObject(item) } }

  /**
  editItem:

  :param: item BankableModelObject
  */
  func editItem(item: BankableModelObject) {
    navigationController?.pushViewController(item.editingViewController(), animated: true)
  }

  /**
  detailItem:

  :param: item BankableModelObject
  */
  func detailItem(item: BankableModelObject) {
    navigationController?.pushViewController(item.detailViewController(), animated: true)
  }

  /**
  toggleItemsForSection:

  :param: section Int
  */
  func toggleItemsForSection(section: Int) {
    if hiddenSections ∋ section { hiddenSections = hiddenSections.filter{$0 != section} }
    else                        { hiddenSections.append(section) }
    collectionView?.reloadSections(NSIndexSet(index: section))
  }

  /**
  segmentedControlValueDidChange:

  :param: sender UISegmentedControl
  */
  func segmentedControlValueDidChange(sender: UISegmentedControl) {
    useListView = sender.selectedSegmentIndex == 0
    layout.viewingMode = useListView ? .List : .Thumbnail
    layout.invalidateLayout()
  }

  /**
  importBankObject:

  :param: sender AnyObject?
  */
  func importBankObjects() { MSLogInfo("item import not yet implemented")  }

  /**
  searchBankObjects:

  :param: sender AnyObject?
  */
  func searchBankObjects() { MSLogInfo("item search not yet implemented")  }

  /**
  dismiss:

  :param: sender AnyObject?
  */
  func dismiss(sender: AnyObject?) { MSRemoteAppController.sharedAppController().showMainMenu()  }


  ////////////////////////////////////////////////////////////////////////////////
  /// MARK: - Zooming a cell's item
  ////////////////////////////////////////////////////////////////////////////////


  private var zoomedItem: BankableModelObject?

  /**
  zoomItem:

  :param: item BankableModelObject
  */
  func zoomItem(item: BankableModelObject) {

    zoomedItem = item

    if let zoom = zoomView {

      zoom.item = item
      zoom.backgroundImage = view.blurredSnapshot()
      view.addSubview(zoom)
      view.setNeedsUpdateConstraints()

    }

  }

}

////////////////////////////////////////////////////////////////////////////////
/// MARK: - BankCollectionZoomDelegate
////////////////////////////////////////////////////////////////////////////////
extension BankCollectionController: BankCollectionZoomDelegate {

  /**
  didDismissZoomView:

  :param: zoom BankCollectionZoom
  */
  func didDismissZoomView(zoom: BankCollectionZoom) {
    precondition(zoom === zoomView, "exactly who's zoom view is this, anyway?")
    zoom.removeFromSuperview()
  }

  /**
  didDismissForDetailZoomView:

  :param: zoom BankCollectionZoom
  */
  func didDismissForDetailZoomView(zoom: BankCollectionZoom) {
    precondition(zoom === zoomView, "exactly who's zoom view is this, anyway?")
    zoom.removeFromSuperview()
    navigationController?.pushViewController(zoomedItem!.detailViewController(), animated: true)
  }

  /**
  didDismissForEditingZoomView:

  :param: zoom BankCollectionZoom
  */
  func didDismissForEditingZoomView(zoom: BankCollectionZoom) {
    precondition(zoom === zoomView, "exactly who's zoom view is this, anyway?")
    zoom.removeFromSuperview()
    navigationController?.pushViewController(zoomedItem!.editingViewController(), animated: true)
  }

}

////////////////////////////////////////////////////////////////////////////////
/// MARK: - Selecting/deselecting
////////////////////////////////////////////////////////////////////////////////
extension BankCollectionController {

  /**
  selectAll:

  :param: sender AnyObject!
  */
  override func selectAll(sender: AnyObject!) {

    // Make sure we are in export selection mode
    if exportSelectionMode {

      if let controller = collectionItemsController {
        // Enumerate all the sections
        for (sectionNumber, section) in enumerate(controller.sections as [NSFetchedResultsSectionInfo]) {

          // Enumerate the items in this section
          for row in 0..<section.numberOfObjects {

            // Create the index path
            let indexPath = NSIndexPath(forRow: row, inSection: sectionNumber)

            // Get the corresponding item
            let item = controller.objectAtIndexPath(indexPath) as BankableModelObject

            // Add the item to our export selection
            exportSelection.append(item)

            // Select the cell
            collectionView!.selectItemAtIndexPath(indexPath, animated: true, scrollPosition: .None)

            // Update the cell if it is visible
            if let cell = collectionView!.cellForItemAtIndexPath(indexPath) as? BankCollectionCell {
              cell.indicatorImage = IndicatorImageSelected
            }
            
          }
        
        }

      }

      // TODO: Add selection when using `collectionItems`

    }

  }

  /**
  deselectAll:

  :param: sender AnyObject!
  */
  func deselectAll(sender: AnyObject!) {

    // Make sure we are in export selection mode
    if exportSelectionMode {

      // Remove all the items from export selection
      exportSelection.removeAll(keepCapacity: false)

      // Enumerate the selected index paths
      for indexPath in collectionView!.indexPathsForSelectedItems() as [NSIndexPath] {

        // Deselect the cell
        collectionView!.deselectItemAtIndexPath(indexPath, animated: true)

        // Update the cell image if it is visible
        if let cell = collectionView!.cellForItemAtIndexPath(indexPath) as? BankCollectionCell {
          cell.indicatorImage = IndicatorImage
        }

      }

    }

  }

}

////////////////////////////////////////////////////////////////////////////////
/// MARK: - UICollectionViewDataSource
////////////////////////////////////////////////////////////////////////////////
extension BankCollectionController: UICollectionViewDataSource {

  /**
  collectionView:numberOfItemsInSection:

  :param: collectionView UICollectionView
  :param: section Int

  :returns: Int
  */
  override func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    var count = 0
    if let controller = collectionItemsController {
      if let sections = controller.sections as? [NSFetchedResultsSectionInfo] {
        if sections.count > section { count = sections[section].numberOfObjects }
      }
    } else if collectionItems != nil {
      count = collectionItems!.count
    }
    return count
  }

  /**
  collectionView:cellForItemAtIndexPath:

  :param: collectionView UICollectionView
  :param: indexPath NSIndexPath

  :returns: UICollectionViewCell
  */
  override func collectionView(collectionView: UICollectionView,
        cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell
  {
    let cell = collectionView.dequeueReusableCellWithReuseIdentifier(CellIdentifier,
                                                        forIndexPath: indexPath) as BankCollectionCell
    if let controller = collectionItemsController {
      cell.item = (controller[indexPath] as BankableModelObject)
    } else if let items = collectionItems {
      cell.item = items[indexPath.row]
    }
    cell.detailActionHandler   = {[unowned self] (cell) in self.detailItem(cell.item!)}
    cell.previewActionHandler  = {[unowned self] (cell) in self.zoomItem(cell.item!)}

    return cell
  }

  /**
  numberOfSectionsInCollectionView:

  :param: collectionView UICollectionView

  :returns: Int
  */
  override func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
    if let controller = collectionItemsController {
      return (controller.sections as [NSFetchedResultsSectionInfo]).count
    } else if collectionItems != nil {
      return 1
    } else {
      return 0
    }
  }

  /**
  collectionView:viewForSupplementaryElementOfKind:atIndexPath:

  :param: collectionView UICollectionView
  :param: kind String
  :param: indexPath NSIndexPath

  :returns: UICollectionReusableView
  */
  override func        collectionView(collectionView: UICollectionView,
    viewForSupplementaryElementOfKind kind: String,
                          atIndexPath indexPath: NSIndexPath) -> UICollectionReusableView
  {
    var view: UICollectionReusableView?

    if kind == UICollectionElementKindSectionHeader && collectionItemsController != nil {
      let header =
        collectionView.dequeueReusableSupplementaryViewOfKind(kind,
                                          withReuseIdentifier: HeaderIdentifier,
                                                 forIndexPath: indexPath) as BankCollectionHeader
      let section = indexPath.section
      // FIXME: Crash when loading component device codes
      if let sections = collectionItemsController!.sections as? [NSFetchedResultsSectionInfo] {
        if sections.count > section {
          let sectionInfo = sections[section]
          header.title = sectionInfo.name
          header.toggleActionHandler = {[unowned self] _ in
            (self.collectionViewLayout! as BankCollectionLayout).toggleItemsForSection(section)
          }
        }
      }
      header.title = (collectionItemsController!.sections as [NSFetchedResultsSectionInfo])[indexPath.section].name

      view = header
    }

    return view ?? UICollectionReusableView()
  }

}

////////////////////////////////////////////////////////////////////////////////
/// MARK: - UICollectionViewDelegate
////////////////////////////////////////////////////////////////////////////////
extension BankCollectionController: UICollectionViewDelegate {

  /**
  collectionView:willDisplayCell:forItemAtIndexPath:

  :param: collectionView UICollectionView
  :param: cell UICollectionViewCell
  :param: indexPath NSIndexPath
  */

  override func collectionView(collectionView: UICollectionView,
               willDisplayCell cell: UICollectionViewCell,
            forItemAtIndexPath indexPath: NSIndexPath)
  {

    let bankCell = cell as BankCollectionCell
    bankCell.indicatorImage = (exportSelectionMode
                                ? (exportSelection ∋ bankCell.item! ? IndicatorImageSelected : IndicatorImage)
                                : nil)
  }

  /**
  collectionView:didDeselectItemAtIndexPath:

  :param: collectionView UICollectionView
  :param: indexPath NSIndexPath
  */
  override func collectionView(collectionView: UICollectionView, didDeselectItemAtIndexPath indexPath: NSIndexPath) {

    let cell = collectionView.cellForItemAtIndexPath(indexPath) as BankCollectionCell

    // Check if we are selecting items to export
    if exportSelectionMode {
      exportSelection = exportSelection.filter{$0 != cell.item}  // Remove from our collection of items to export
      cell.indicatorImage = IndicatorImage                       // Change the indicator to normal
    }

  }

  /**
  collectionView:didSelectItemAtIndexPath:

  :param: collectionView UICollectionView
  :param: indexPath NSIndexPath
  */
  override func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {

    let cell = collectionView.cellForItemAtIndexPath(indexPath) as BankCollectionCell

    // Check if we are selecting items to export
    if exportSelectionMode {
      exportSelection.append(cell.item!)             // Add to our collection of items to export
      cell.indicatorImage = IndicatorImageSelected  // Change indicator to selected
    }

    // Otherwise we push the item's detail view controller
    else { navigationController?.pushViewController(cell.item!.detailViewController(), animated:true) }

  }

}

////////////////////////////////////////////////////////////////////////////////
/// MARK: - NSFetchedResultsControllerDelegate
////////////////////////////////////////////////////////////////////////////////
extension BankCollectionController: NSFetchedResultsControllerDelegate {

  /**
  controllerWillChangeContent:

  :param: controller NSFetchedResultsController
  */
  func controllerWillChangeContent(controller: NSFetchedResultsController) { updatesBlock = NSBlockOperation() }

  /**
  controller:didChangeSection:atIndex:forChangeType:

  :param: controller NSFetchedResultsController
  :param: sectionInfo NSFetchedResultsSectionInfo
  :param: sectionIndex Int
  :param: type NSFetchedResultsChangeType
  */
  func    controller(controller: NSFetchedResultsController,
    didChangeSection sectionInfo: NSFetchedResultsSectionInfo,
             atIndex sectionIndex: Int,
       forChangeType type: NSFetchedResultsChangeType)
  {
    updatesBlock?.addExecutionBlock { [unowned self] in
      switch type {
        case .Insert: self.collectionView?.insertSections(NSIndexSet(index:sectionIndex))
        case .Delete: self.collectionView?.deleteSections(NSIndexSet(index:sectionIndex))
        default: break
      }
    }
  }

  /**
  controller:didChangeObject:atIndexPath:forChangeType:newIndexPath:

  :param: controller NSFetchedResultsController
  :param: anObject AnyObject
  :param: indexPath NSIndexPath?
  :param: type NSFetchedResultsChangeType
  :param: newIndexPath NSIndexPath?
  */
  func controller(controller: NSFetchedResultsController,
  didChangeObject anObject: AnyObject,
      atIndexPath indexPath: NSIndexPath?,
    forChangeType type: NSFetchedResultsChangeType,
     newIndexPath: NSIndexPath?)
  {
    updatesBlock?.addExecutionBlock{[unowned self] in
      switch type {
        case .Insert: self.collectionView?.insertItemsAtIndexPaths([newIndexPath!])
        case .Delete: self.collectionView?.deleteItemsAtIndexPaths([indexPath!])
        case .Move:   self.collectionView?.deleteItemsAtIndexPaths([indexPath!])
                      self.collectionView?.insertItemsAtIndexPaths([newIndexPath!])
        default: break
      }
    }
  }

  /**
  controllerDidChangeContent:

  :param: controller NSFetchedResultsController
  */
  func controllerDidChangeContent(controller: NSFetchedResultsController) {
    collectionView?.performBatchUpdates({[unowned self] in NSOperationQueue.mainQueue().addOperation(self.updatesBlock!) },
                             completion: nil)
  }

}

////////////////////////////////////////////////////////////////////////////////
/// MARK: - UITextFieldDelegate
////////////////////////////////////////////////////////////////////////////////
extension BankCollectionController: UITextFieldDelegate {

  /**
  textFieldShouldEndEditing:

  :param: textField UITextField

  :returns: Bool
  */
  func textFieldShouldEndEditing(textField: UITextField) -> Bool {
    if existingFiles ∋ textField.text {
      textField.textColor = UIColor(name:"fire-brick")
      return false
    }
    return true
  }

  /**
  textField:shouldChangeCharactersInRange:replacementString:

  :param: textField UITextField
  :param: range NSRange
  :param: string String

  :returns: Bool
  */
  func                  textField(textField: UITextField,
    shouldChangeCharactersInRange range: NSRange,
                replacementString string: String) -> Bool
  {
    let text = (range.length == 0
                       ? textField.text + string
                       : (textField.text as NSString).stringByReplacingCharactersInRange(range, withString:string))
    let nameInvalid = existingFiles ∋ text
    textField.textColor = nameInvalid ? UIColor(name: "fire-brick") : TextFieldTextColor
    exportAlertAction?.enabled = !nameInvalid
    return true
  }

  /**
  textFieldShouldReturn:

  :param: textField UITextField

  :returns: Bool
  */
  func textFieldShouldReturn(textField: UITextField) -> Bool { return false }

  /**
  textFieldShouldClear:

  :param: textField UITextField

  :returns: Bool
  */
  func textFieldShouldClear(textField: UITextField) -> Bool { return true }

}