//
//  RemoteElementEditingController.swift
//  Remote
//
//  Created by Jason Cardwell on 10/26/14.
//  Copyright (c) 2014 Moondeer Studios. All rights reserved.
//

import Foundation
import UIKit
import CoreImage
import MoonKit

@objc protocol EditingDelegate: NSObjectProtocol {
  func editorDidCancel(editor: RemoteElementEditingController)
  func editorDidSave(editor: RemoteElementEditingController)
}

extension UIGestureRecognizerState: Printable {
  public var description: String {
    switch self {
      case .Began: return "Began"
      case .Possible: return "Possible"
      case .Changed: return "Changed"
      case .Ended: return "Ended"
      case .Cancelled: return "Cancelled"
      case .Failed: return "Failed"
    }
  }
}

extension RemoteElement: EditableBackground {}

class RemoteElementEditingController: UIViewController {

  enum MenuState: Int { case Default, StackedViews }

  weak var delegate: EditingDelegate?

  /// MARK: Model-related properties
  ////////////////////////////////////////////////////////////////////////////////

  private(set) var remoteElement: RemoteElement!
  let editingTransitioningDelegate = RemoteElementEditingTransitioningDelegate()
  private(set) weak var presentedSubelementView: RemoteElementView? {
    didSet { if presentedSubelementView != nil { deselectView(presentedSubelementView!) } }
  }
  private(set) var context: NSManagedObjectContext!
  private(set) var changedModelValues: [NSObject:AnyObject]!

  /// MARK: Flag and state properties
  ////////////////////////////////////////////////////////////////////////////////

  var movingSelectedViews: Bool = false {
    didSet {
      let editingState: RemoteElementView.EditingState = movingSelectedViews ? .Moving : .Selected
      apply(selectedViews){$0.editingState = editingState}
      updateState()
    }
  }
  var popoverActive = false
  var presetsActive = false
  var menuState: MenuState = .Default

  /// MARK: Geometry
  ////////////////////////////////////////////////////////////////////////////////

  var appliedTranslation = CGPoint.zeroPoint
  var appliedScale: CGFloat = 1.0
  var longPressPreviousLocation = CGPoint.zeroPoint
  var contentRect = CGRect.zeroRect
  var startingPanOffset: CGFloat = 0.0
  let allowableSourceViewYOffset = ClosedInterval<CGFloat>(-44, 44)
  var maxSizeCache: [String:CGSize] = [:]
  var minSizeCache: [String:CGSize] = [:]

  /// MARK: Bar button items
  ////////////////////////////////////////////////////////////////////////////////

  var singleSelButtons: [UIBarButtonItem] = []
  var anySelButtons: [UIBarButtonItem] = []
  var noSelButtons: [UIBarButtonItem] = []
  var multiSelButtons: [UIBarButtonItem] = []
  var undoButton: MSBarButtonItem!

  /// MARK: Toolbars
  ////////////////////////////////////////////////////////////////////////////////

  weak var currentToolbar: UIToolbar! {
    didSet {
      if currentToolbar != nil && oldValue != nil && currentToolbar != oldValue {
        let animations: (Void) -> Void = { self.currentToolbar.hidden = false; oldValue.hidden = true }
        UIView.animateWithDuration(0.25, animations: animations, completion: nil)
      }
    }
  }

  var topToolbar: UIToolbar!
  var emptySelectionToolbar: UIToolbar!
  var nonEmptySelectionToolbar: UIToolbar!
  var focusSelectionToolbar: UIToolbar!

  var toolbars: [UIToolbar] { return [topToolbar, emptySelectionToolbar, nonEmptySelectionToolbar, focusSelectionToolbar] }

  /// MARK: Gestures
  ////////////////////////////////////////////////////////////////////////////////

  weak var longPressGesture: LongPressGesture!
  weak var pinchGesture: UIPinchGestureRecognizer!
  weak var oneTouchDoubleTapGesture: UITapGestureRecognizer!
  weak var multiselectGesture: MultiselectGestureRecognizer!
  weak var anchoredMultiselectGesture: MultiselectGestureRecognizer!
  weak var twoTouchPanGesture: PanGesture!
  weak var toolbarLongPressGesture: LongPressGesture!
  // weak var oneTouchTapGesture: UITapGestureRecognizer?
  // weak var twoTouchTapGesture: UITapGestureRecognizer?
  // weak var panGesture: UIPanGestureRecognizer?
  var gestureManager: GestureManager!

  /// MARK: View-related properties
  ////////////////////////////////////////////////////////////////////////////////

  var focusView: RemoteElementView? {
    didSet {
      oldValue?.editingState = .Selected
      focusView?.editingState = .Focus
      updateState()
    }
  }

  var sourceView: RemoteElementView!
  var sourceViewCenterYConstraint: NSLayoutConstraint!
  weak var sourceViewWidthConstraint: NSLayoutConstraint?
  weak var sourceViewHeightConstraint: NSLayoutConstraint?
  var sourceViewSize: CGSize? {
    didSet {
      if sourceViewSize == nil {
        if let c = sourceViewWidthConstraint {
          sourceView.removeConstraint(c)
          sourceViewWidthConstraint = nil
        }
        if let c = sourceViewHeightConstraint {
          sourceView.removeConstraint(c)
          sourceViewHeightConstraint = nil
        }
      }
      // TODO: Handle updating this value for dynamic subelement movement
    }
  }
  var selectedViews: OrderedSet<RemoteElementView> = []

  /// Methods
  ////////////////////////////////////////////////////////////////////////////////

  /**
  subelementClass

  :returns: RemoteElementView.Type
  */
//  class func subelementClass() -> RemoteElementView.Type { return RemoteElementView.self }

  /**
  isSubelementKind:

  :param: obj AnyObject

  :returns: Bool
  */
//  class func isSubelementKind(obj: AnyObject) -> Bool { return obj is RemoteElementView }

  /**
  elementClass

  :returns: RemoteElementView.Type
  */
  class func elementClass() -> RemoteElementView.Type { return RemoteElementView.self }

  /**
  Convenience method that calls the following additional methods:
  - `updateBarButtonItems`
  - `updateToolbarDisplayed`
  - `updateGesturesEnabled`
  */
  func updateState() { MSLogDebug(""); updateBarButtonItems(); updateToolbarDisplayed(); updateGesturesEnabled() }

  /**
  clearCacheForViews:

  :param: views [RemoteElementView]
  */
  func clearCacheForViews(views: OrderedSet<RemoteElementView>) {
    for identifier in (views.map{$0.model.uuid}) {
      maxSizeCache.removeValueForKey(identifier)
      minSizeCache.removeValueForKey(identifier)
    }
  }


  /// MARK: Initialization
  ////////////////////////////////////////////////////////////////////////////////

  /**
  editingControllerForElement:

  :param: element RemoteElement

  :returns: RemoteElementEditingController
  */
  class func editingControllerForElement(element: RemoteElement) -> RemoteElementEditingController {
    return editingControllerForElement(element, size: nil)
  }

  /**
  editingControllerForElement:

  :param: element RemoteElement

  :returns: RemoteElementEditingController
  */
  class func editingControllerForElement(element: RemoteElement, size: CGSize? = nil) -> RemoteElementEditingController {
    if let remote = element as? Remote {
      return RemoteEditingController(element: remote, size: size)
    } else if let buttonGroup = element as? ButtonGroup {
      return ButtonGroupEditingController(element: buttonGroup, size: size)
    } else if let button = element as? Button {
      return ButtonEditingController(element: button, size: size)
    } else {
      return RemoteElementEditingController(element: element, size: nil)
    }
  }

  /**
  initWithElement:

  :param: element RemoteElement
  */
  convenience init(element: RemoteElement) { self.init(element: element, size: nil) }

  /**
  initWithElement:size:

  :param: element RemoteElement
  :param: size CGSize? = nil
  */
  required init(element: RemoteElement, size: CGSize? = nil) {
    super.init()
    sourceViewSize = size
    context = CoreDataManager.childContextOfType(.MainQueueConcurrencyType, forContext: element.managedObjectContext!)
    context.performBlockAndWait {
      self.changedModelValues = element.changedValues()
      self.remoteElement = self.context.existingObjectWithID(element.objectID, error: nil) as RemoteElement
    }
    modalPresentationStyle = .Custom
  }

  /** init */
  override init() { super.init() }

  /**
  init:bundle:

  :param: nibNameOrNil String?
  :param: nibBundleOrNil NSBundle?
  */
  override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: NSBundle?) {
    super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
  }

  /**
  init:

  :param: aDecoder NSCoder
  */
  required init(coder aDecoder: NSCoder) { super.init(coder: aDecoder) }


  /** loadView */
  override func loadView() {

    // Create the root view
    view = UIView(frame: UIScreen.mainScreen().bounds)

    // Create the source view
    sourceView = RemoteElementView.viewWithModel(remoteElement) //self.dynamicType.elementClass()(model: remoteElement)
    if let size = sourceViewSize {
      let (widthConstraint, heightConstraint) = sourceView.constrainSize(size)
      sourceViewWidthConstraint = widthConstraint
      sourceViewHeightConstraint = heightConstraint
    }
    sourceView.editingMode = sourceView.model.elementType
    view.addSubview(sourceView)

    // Create the top toolbar
    topToolbar =  UIToolbar(frame: CGRect(size: CGSize(width: 320, height: 44)))
    topToolbar.setTranslatesAutoresizingMaskIntoConstraints(false)
    topToolbar.translucent = true
    undoButton = ViewDecorator.fontAwesomeBarButtonItemWithName("undo", target: self, selector: "resetAction")
    let cancelButton = ViewDecorator.fontAwesomeBarButtonItemWithName("remove", target: self, selector: "cancelAction")
    let saveButton = ViewDecorator.fontAwesomeBarButtonItemWithName("save", target: self, selector: "saveAction")
    let flexibleSpace = UIBarButtonItem.flexibleSpace()
    topToolbar.items = [cancelButton, flexibleSpace, undoButton, flexibleSpace, saveButton]
    anySelButtons += [undoButton, saveButton]
    view.addSubview(topToolbar)

    // Create the empty selection toolbar
    emptySelectionToolbar = UIToolbar(frame: CGRect(x: 0, y: 436, width: 320, height: 44))
    emptySelectionToolbar.setTranslatesAutoresizingMaskIntoConstraints(false)
    emptySelectionToolbar.translucent = true
    let plusButton = ViewDecorator.fontAwesomeBarButtonItemWithName("plus", target: self, selector: "addSubelement")
    let editButton = ViewDecorator.fontAwesomeBarButtonItemWithName("picture", target: self, selector: "editBackground")
    let boundsButton = ViewDecorator.fontAwesomeBarButtonItemWithName("bounds", target: self, selector: "toggleBounds")
    let presetsButton = ViewDecorator.fontAwesomeBarButtonItemWithName("hdd", target: self, selector: "presets")
    emptySelectionToolbar.items = join(flexibleSpace, [plusButton, editButton, boundsButton, presetsButton])
    anySelButtons += [editButton, boundsButton, presetsButton]
    view.addSubview(emptySelectionToolbar)

    // Create the non-empty selection toolbar
    nonEmptySelectionToolbar = UIToolbar(frame: CGRect(x: 0, y: 436, width: 320, height: 44))
    nonEmptySelectionToolbar.setTranslatesAutoresizingMaskIntoConstraints(false)
    nonEmptySelectionToolbar.translucent = true
    nonEmptySelectionToolbar.hidden = true
    let editSubelementButton = ViewDecorator.fontAwesomeBarButtonItemWithName("edit", target: self, selector: "editSubelement")
    let trashButton = ViewDecorator.fontAwesomeBarButtonItemWithName("trash", target: self, selector: "delete:")
    let duplicateButton = ViewDecorator.fontAwesomeBarButtonItemWithName("th-large", target: self, selector: "duplicate")
    let copyButton = ViewDecorator.fontAwesomeBarButtonItemWithName("copy", target: self, selector: "copyStyle")
    let pasteButton = ViewDecorator.fontAwesomeBarButtonItemWithName("paste", target: self, selector: "pasteStyle")
    nonEmptySelectionToolbar.items =
      join(flexibleSpace, [editSubelementButton, trashButton, duplicateButton, copyButton, pasteButton])
    anySelButtons += [duplicateButton, pasteButton]
    singleSelButtons += [editSubelementButton, copyButton]
    view.addSubview(nonEmptySelectionToolbar)

    // Create the focus selection toolbar
    focusSelectionToolbar = UIToolbar(frame: CGRect(x: 0, y: 436, width: 320, height: 44))
    focusSelectionToolbar.setTranslatesAutoresizingMaskIntoConstraints(false)
    focusSelectionToolbar.translucent = true
    focusSelectionToolbar.hidden = true
    let alignNames = ["align-bottom-edges",
                      "align-top-edges",
                      "align-left-edges",
                      "align-right-edges",
                      "align-center-y",
                      "align-center-x"]
    let alignTitles: [NSAttributedString] = alignNames.map{ViewDecorator.fontAwesomeTitleWithName($0, size: 48.0)}
    let alignSelectors: [Selector] = ["alignBottomEdges",
                                      "alignTopEdges",
                                      "alignLeftEdges",
                                      "alignRightEdges",
                                      "alignVerticalCenters",
                                      "alignHorizontalCenters"]
    let align = MSPopupBarButton(title: UIFont.fontAwesomeIconForName("align-edges"), style: .Plain, target: nil, action: nil)
    let textAttributes = [NSFontAttributeName: UIFont(awesomeFontWithSize:32.0)]
    align.setTitleTextAttributes(textAttributes, forState: .Normal)
    align.setTitleTextAttributes(textAttributes, forState: .Highlighted)
    align.delegate = self
    for i in 0..<alignTitles.count {
      align.addItemWithAttributedTitle(alignTitles[i], target: self, action: alignSelectors[i])
    }
    let resizeNames = ["align-horizontal-size", "align-vertical-size", "align-size-exact"]
    let resizeTitles: [NSAttributedString] = resizeNames.map{ViewDecorator.fontAwesomeTitleWithName($0, size: 48.0)}
    let resizeSelectors: [Selector] = ["resizeHorizontallyFromFocusView",
                                       "resizeVerticallyFromFocusView",
                                       "resizeFromFocusView"]
    let resize = MSPopupBarButton(title: UIFont.fontAwesomeIconForName("align-size"), style: .Plain, target: nil, action: nil)
    resize.setTitleTextAttributes(textAttributes, forState: .Normal)
    resize.setTitleTextAttributes(textAttributes, forState: .Highlighted)
    resize.delegate = self
    for i in 0..<resizeTitles.count {
      resize.addItemWithAttributedTitle(resizeTitles[i], target: self, action: resizeSelectors[i])
    }
    focusSelectionToolbar.items = [flexibleSpace, align, flexibleSpace, resize, flexibleSpace]
    multiSelButtons += [align, resize]
    view.addSubview(focusSelectionToolbar)

    // Add some constraints
    let format = "\n".join("|[top]|",
                           "|[empty]|",
                           "|[nonempty]|",
                           "|[focus]|",
                           "V:|[top]",
                           "V:[empty]|",
                           "V:[nonempty]|",
                           "V:[focus]|",
                           "source.center = self.center")

    let views = ["top":      topToolbar,
                 "empty":    emptySelectionToolbar,
                 "nonempty": nonEmptySelectionToolbar,
                 "focus":    focusSelectionToolbar,
                 "source":   sourceView]

    view.constrain(format, views: views)

    // Keep a refrence to the source view center y constraint
    let predicate = NSPredicate(format: "firstItem == %@" +
                                        "AND secondItem == %@ " +
                                        "AND firstAttribute == \(NSLayoutAttribute.CenterY.rawValue)" +
                                        "AND secondAttribute == \(NSLayoutAttribute.CenterY.rawValue)" +
                                        "AND relation == \(NSLayoutRelation.Equal.rawValue)", sourceView, view)
    sourceViewCenterYConstraint = view.constraintMatching(predicate)


    // Set the initial current toolbar value
    currentToolbar = emptySelectionToolbar

  }

  /** viewDidLoad */
  override func viewDidLoad() {
    super.viewDidLoad()
    attachGestureRecognizers()
    contentRect = view.frame.rectByInsetting(dx: 0.0, dy: topToolbar.bounds.height)
  }

  /**
  canBecomeFirstResponder

  :returns: Bool
  */
  override func canBecomeFirstResponder() -> Bool { return true }

  /** registerForNotifications */
  func registerForNotifications() {
    NSNotificationCenter.defaultCenter().addObserverForName(UIMenuControllerDidHideMenuNotification,
      object: UIMenuController.sharedMenuController(),
      queue: NSOperationQueue.mainQueue(),
      usingBlock: {[unowned self](note: NSNotification!) -> Void in self.menuState = .Default })
  }

  /** Removes controller from notification center */
  deinit { NSNotificationCenter.defaultCenter().removeObserver(self) }

  /**
  canPerformAction:withSender:

  :param: action Selector
  :param: sender AnyObject?

  :returns: Bool
  */
  override func canPerformAction(action: Selector, withSender sender: AnyObject?) -> Bool {
    return menuState == .StackedViews
             ? String(_sel: action).hasPrefix("menuAction_")
             : super.canPerformAction(action, withSender: sender)
  }

  /**
  viewDidAppear:

  :param: animated Bool
  */
  override func viewDidAppear(animated: Bool) {
    super.viewDidAppear(animated)
    becomeFirstResponder()
    registerForNotifications()
    updateState()
    MSLogDebug(view.framesDescription())
  }

  /**
  viewDidDisappear:

  :param: animated Bool
  */
  override func viewDidDisappear(animated: Bool) {
    super.viewDidDisappear(animated)
    resignFirstResponder()
    NSNotificationCenter.defaultCenter()
      .removeObserver(self, name: UIMenuControllerDidHideMenuNotification, object: UIMenuController.sharedMenuController())
  }

}

/// MARK: - Selecting subelements
////////////////////////////////////////////////////////////////////////////////
extension RemoteElementEditingController {

  /**
  selectView:

  :param: view RemoteElementView
  */
  func selectView(view: RemoteElementView) { selectViews(OrderedSet([view])) }

  /**
  selectViews:

  :param: views [RemoteElementView]
  */
  func selectViews(views: OrderedSet<RemoteElementView>) {
    for v in (views ∖ selectedViews) {
      v.editingState = .Selected
      sourceView.bringSubelementViewToFront(v)
    }
    selectedViews ∪= views
    updateState()
  }

  /**
  deselectView:

  :param: view RemoteElementView
  */
  func deselectView(view: RemoteElementView) { deselectViews([view]) }

  /**
  deselectViews:

  :param: views [RemoteElementView]
  */
  func deselectViews(views: OrderedSet<RemoteElementView>) {
    for v in (views ∩ selectedViews) { if v === focusView { focusView = nil } else { v.editingState = .None } }
    selectedViews ∖= views
    updateState()
  }

  /** deselectAll */
  func deselectAll() { focusView = nil; deselectViews(selectedViews) }

  /**
  toggleSelectionForViews:

  :param: views [RemoteElementView]
  */
  func toggleSelectionForViews(views: OrderedSet<RemoteElementView>) {
    selectViews(views ∖ selectedViews)
    deselectViews(views ∩ selectedViews)
  }

  /** toggleBounds */
  func toggleBounds() {  }

  /**
  displayStackedViewDialogForViews:

  :param: stackedViews NSSet
  */
  func displayStackedViewDialogForViews(stackedViews: OrderedSet<RemoteElementView>) {
     println(__FUNCTION__)
    /*
    MSLogDebug(@"%@ select stacked views to include: (%@)",
               ClassTagSelectorString,
               [[[stackedViews allObjects] valueForKey:@"name"]
                  componentsJoinedByString:@", "]);

    _flags.menuState = REEditingMenuStateStackedViews;

    MenuController.menuItems = [[stackedViews allObjects]
                                mapped:
                                ^UIMenuItem *(RemoteElementView * obj, NSUInteger idx) {
      SEL action = NSSelectorFromString($(@"menuAction%@:",
                                          obj.uuid));
      return MenuItem(obj.name, action);
    }];

    [MenuController setTargetRect:[self.view.window
                                   convertRect:[UIView unionFrameForViews:[stackedViews allObjects]]
                                      fromView:_sourceView]
                           inView:self.view];
    MenuController.arrowDirection = UIMenuControllerArrowDefault;
    [MenuController update];
    MenuController.menuVisible = YES;
    */
  }

}

/// MARK: - Exit actions
////////////////////////////////////////////////////////////////////////////////
extension RemoteElementEditingController {

  /** saveAction */
  func saveAction() {
    var success = false
    context.performBlockAndWait {
      var error: NSError?
      success = self.context.save(&error)
      MSHandleError(error)
    }
    if success {
      if delegate != nil { delegate!.editorDidSave(self) }
      else { MSRemoteAppController.sharedAppController().dismissViewController(self, completion: nil) }
    }
  }

  /** resetAction */
  func resetAction() { context.performBlockAndWait { self.context.rollback() } }

  /** cancelAction */
  func cancelAction() {
    context.performBlockAndWait { self.context.rollback() }
    if delegate != nil { delegate!.editorDidCancel(self) }
    else { MSRemoteAppController.sharedAppController().dismissViewController(self, completion: nil) }
  }

}

/// MARK: - Aligning subelements
////////////////////////////////////////////////////////////////////////////////
extension RemoteElementEditingController {

  /** alignVerticalCenters */
  func alignVerticalCenters() { willAlignSelectedViews(); alignSelectedViews(.CenterY); didAlignSelectedViews() }

  /** alignHorizontalCenters */
  func alignHorizontalCenters() { willAlignSelectedViews(); alignSelectedViews(.CenterX); didAlignSelectedViews() }

  /** alignTopEdges */
  func alignTopEdges() { willAlignSelectedViews(); alignSelectedViews(.Top); didAlignSelectedViews() }

  /** alignBottomEdges */
  func alignBottomEdges() { willAlignSelectedViews(); alignSelectedViews(.Bottom); didAlignSelectedViews() }

  /** alignLeftEdges */
  func alignLeftEdges() { willAlignSelectedViews(); alignSelectedViews(.Left); didAlignSelectedViews() }

  /** alignRightEdges */
  func alignRightEdges() { willAlignSelectedViews(); alignSelectedViews(.Right); didAlignSelectedViews() }

  /** Override point for subclasses to perform additional work pre-alignment. */
  func willAlignSelectedViews() {}

  /**
  Sends `alignSubelements:toSibling:attribute:` to the `sourceView` to perform actual alignment

  :param: alignment `NSLayoutAttribute` to use when aligning the `selectedViews` to the `focusView`
  */
  func alignSelectedViews(alignment: NSLayoutAttribute) {
    precondition(focusView != nil, "there must be a view to align to")
    willAlignSelectedViews()
    sourceView.alignSubelements(selectedViews ∖ [focusView!], toSibling: focusView!, attribute: alignment)
    didAlignSelectedViews()
  }

  /** Override point for subclasses to perform additional work post-alignment. */
  func didAlignSelectedViews() { clearCacheForViews(selectedViews) }

}

/// MARK: - Resizing subelements
////////////////////////////////////////////////////////////////////////////////
extension RemoteElementEditingController {

  /** resizeFromFocusView */
  func resizeFromFocusView() {
    willResizeSelectedViews()
    resizeSelectedViews(.Width)
    resizeSelectedViews(.Height)
    didResizeSelectedViews()
  }

  /** resizeHorizontallyFromFocusView */
  func resizeHorizontallyFromFocusView() { willResizeSelectedViews(); resizeSelectedViews(.Width); didResizeSelectedViews() }

  /** resizeVerticallyFromFocusView */
  func resizeVerticallyFromFocusView() { willResizeSelectedViews(); resizeSelectedViews(.Width); didResizeSelectedViews() }

  /** Override point for subclasses to perform additional work pre-sizing. */
  func willResizeSelectedViews() {}

  /**
  Sends `resizeSubelements:toSibling:attribute:` to the `sourceView` to perform actual resizing.

  :param: axis `NSLayoutAttribute` specifying whether resizing should involve width or height
  */
  func resizeSelectedViews(axis: NSLayoutAttribute) {
    precondition(focusView != nil, "there must be a view to resize to")
    willResizeSelectedViews()
    sourceView.resizeSubelements(selectedViews ∖ [focusView!], toSibling: focusView!, attribute: axis)
    didResizeSelectedViews()
  }

  /** Override point for subclasses to perform additional work pre-sizing. */
  func didResizeSelectedViews() {}

  /** Override point for subclasses to perform additional work pre-scaling. */
  func willScaleSelectedViews() {}

  /**
  Performs a sanity check on the scale to be applied and then sends `scaleSubelements:scale:` to the `sourceView`
  to perform actual scaling.

  :param: scale CGFloat The scale to apply to the current selection

  :returns: CGFloat The actual scale value applied to the current selection
  */
  func scaleSelectedViews(scale: CGFloat) -> CGFloat {

    let isValid =  {
      (view: RemoteElementView, size: CGSize, inout max: CGSize, inout min: CGSize) -> Bool in
        let frame = view.convertRect(view.frame, toView: nil)
        let cachedMax = self.maxSizeCache[view.model.uuid]
        let cachedMin = self.minSizeCache[view.model.uuid]
        if cachedMax != nil && cachedMin != nil {
          max = cachedMax!
          min = cachedMin!
        } else {
          let deltaSize = CGSizeGetDelta(frame.size, view.maximumSize)
          let maximumSize = view.maximumSize
          let maxFrame = CGRect(x: frame.origin.x + deltaSize.width / CGFloat(2),
                                y: frame.origin.y + deltaSize.height / CGFloat(2),
                                width: maximumSize.width,
                                height: maximumSize.height)
          if !self.contentRect.contains(maxFrame) {
            let intersection = self.contentRect.rectByIntersecting(maxFrame)
            let deltaMin = CGPointGetDeltaABS(frame.origin, intersection.origin)
            let deltaMax = CGPointGetDeltaABS(CGPoint(x: frame.maxX, y: frame.maxY),
                                                CGPoint(x: intersection.maxX, y: intersection.maxY))
            max = CGSize(width: (frame.size.width + Swift.min(deltaMin.x, deltaMax.x) * CGFloat(2.0)),
                         height: (frame.size.height + Swift.min(deltaMin.y, deltaMax.y) * CGFloat(2.0)))
            if view.model.constraintManager.proportionLock {
              if max.width < max.height {
                max.height = frame.size.height / frame.size.width * max.width
              } else {
                max.width = frame.size.width / frame.size.height * max.height
              }
            }
          } else {
            max = view.maximumSize
          }
          min = view.minimumSize

          self.maxSizeCache[view.model.uuid] = max
          self.minSizeCache[view.model.uuid] = min

        }
        return (   size.width <= max.width
                && size.height <= max.height
                && size.width >= min.width
                && size.height >= min.height)
    }

    var scaleRejections: [CGFloat] = []
    for view in selectedViews {
      let scaledSize = view.bounds.size.sizeByApplyingTransform(CGAffineTransform(sx: scale, sy: scale))
      var maxSize = CGSize.zeroSize, minSize = CGSize.zeroSize
      if !isValid(view, scaledSize, &maxSize, &minSize) {
        let boundedSize = CGSize(square: (scale > CGFloat(1) ? maxSize.minAxis : minSize.maxAxis))
        let validScale = boundedSize.width / view.bounds.width
        scaleRejections.append(validScale)
      }
    }

    appliedScale = (scaleRejections.count > 0
                        ? (scale > CGFloat(1) ? minElement(scaleRejections) : maxElement(scaleRejections))
                        : scale)
    willScaleSelectedViews()
    for view in selectedViews { view.scale(appliedScale) }
    didScaleSelectedViews()

    return appliedScale
  }

  /** Override point for subclasses to perform additional work post-scaling. */
  func didScaleSelectedViews() {}

}

/// MARK: - Gesture-related methods
////////////////////////////////////////////////////////////////////////////////
extension RemoteElementEditingController {

  /** updateGesturesEnabled */
  func updateGesturesEnabled() {
    longPressGesture.enabled = focusView == nil
    pinchGesture.enabled = selectedViews.count > 0
    oneTouchDoubleTapGesture.enabled = !movingSelectedViews
    multiselectGesture.enabled = !movingSelectedViews
    anchoredMultiselectGesture.enabled = !movingSelectedViews
    twoTouchPanGesture.enabled = sourceView.bounds.height >= (view.bounds.height - length(allowableSourceViewYOffset))

    let enabledGestures = ", ".join((view.gestureRecognizers as [UIGestureRecognizer]).filter{$0.enabled && $0.nametag != nil}.map{$0.nametag})
    let disabledGestures = ", ".join((view.gestureRecognizers as [UIGestureRecognizer]).filter{!$0.enabled && $0.nametag != nil}.map{$0.nametag})
    MSLogDebug("enabled gestures: \(enabledGestures)\ndisabled gestures: \(disabledGestures)")

  }

  /** attachGestureRecognizers */
  func attachGestureRecognizers() {

    longPressGesture = {
      let gesture = LongPressGesture(handler: {[unowned self] in self.handleLongPress(self.longPressGesture)})
      gesture.nametag = "longPressGesture"
      self.view.addGestureRecognizer(gesture)
      return gesture
    }()

    pinchGesture = {
      let gesture = UIPinchGestureRecognizer(target: self, action: "handlePinch:")
      gesture.nametag = "pinchGesture"
      self.view.addGestureRecognizer(gesture)
      return gesture
    }()

    oneTouchDoubleTapGesture = {
      let gesture = UITapGestureRecognizer(target: self, action: "handleTap:")
      gesture.numberOfTapsRequired = 2
      gesture.nametag = "oneTouchDoubleTapGesture"
      self.view.addGestureRecognizer(gesture)
      return gesture
    }()

    multiselectGesture = {
      let gesture = MultiselectGestureRecognizer(target: self, action: "handleSelection:")
      gesture.requireGestureRecognizerToFail(self.oneTouchDoubleTapGesture)
      gesture.requireGestureRecognizerToFail(self.longPressGesture)
      gesture.nametag = "multiselectGesture"
      self.view.addGestureRecognizer(gesture)
      return gesture
    }()

    anchoredMultiselectGesture = {
      let gesture = MultiselectGestureRecognizer(target: self, action: "handleSelection:")
      gesture.numberOfAnchorTouchesRequired = 1
      self.pinchGesture.requireGestureRecognizerToFail(gesture)
      self.multiselectGesture.requireGestureRecognizerToFail(gesture)
      gesture.requireGestureRecognizerToFail(self.longPressGesture)
      gesture.nametag = "anchoredMultiselectGesture"
      self.view.addGestureRecognizer(gesture)
      return gesture
    }()

    twoTouchPanGesture = {
      let gesture = PanGesture(handler: {[unowned self] in self.handlePan(self.twoTouchPanGesture)})
      gesture.minimumNumberOfTouches = 2
      gesture.maximumNumberOfTouches = 2
      gesture.requireGestureRecognizerToFail(self.pinchGesture)
      self.multiselectGesture.requireGestureRecognizerToFail(gesture)
      gesture.enabled = false
      gesture.nametag = "twoTouchPanGesture"
      self.view.addGestureRecognizer(gesture)
      return gesture
    }()

    toolbarLongPressGesture = {
      let gesture = LongPressGesture(handler: {[unowned self] in self.handleLongPress(self.toolbarLongPressGesture)})
      self.longPressGesture.requireGestureRecognizerToFail(gesture)
      gesture.nametag = "toolbarLongPressGesture"
      self.undoButton?.addGestureRecognizer(gesture)
      return gesture
    }()

    createGestureManager()
  }

  /** createGestureManager */
  func createGestureManager() {

    let noPopovers: (Void) -> Bool = {
      [unowned self] in !(self.popoverActive || self.presetsActive) && self.menuState == .Default
    }
    let noToolbars: (UITouch) -> Bool = {
      [unowned self] t in self.toolbars.filter{t.view.isDescendantOfView($0)}.count == 0
    }
    let noPopoversOrToolbars: (UITouch) -> Bool = {touch in noPopovers() && noToolbars(touch)}

    let notMoving: (Void) -> Bool = {
      [unowned self] in !self.movingSelectedViews
    }
    let selectableClass: (UITouch) -> Bool = {
      [unowned self] touch in self.sourceView.objectIsSubelementKind(touch.view)
    }

    gestureManager = GestureManager(gestures: [
      pinchGesture:
        GestureManager.ResponseCollection(
          begin: {[unowned self] in self.selectedViews.count > 0},
          receiveTouch: noPopoversOrToolbars
        ),
      longPressGesture:
        GestureManager.ResponseCollection(
          receiveTouch: {touch in noPopoversOrToolbars(touch) && selectableClass(touch)},
          recognizeSimultaneously: {gesture in true} //{[unowned self] gesture in gesture === self.toolbarLongPressGesture}
        ),
      toolbarLongPressGesture:
        GestureManager.ResponseCollection(
          receiveTouch: {[unowned self] touch in noPopovers() && touch.view.isDescendantOfView(self.topToolbar)}
        ),
      twoTouchPanGesture:
        GestureManager.ResponseCollection(
          receiveTouch: noPopoversOrToolbars
        ),
      oneTouchDoubleTapGesture:
        GestureManager.ResponseCollection(
          begin: notMoving,
          receiveTouch: noPopoversOrToolbars
        ),
      multiselectGesture:
        GestureManager.ResponseCollection(
          begin: notMoving,
          receiveTouch: noPopoversOrToolbars,
          recognizeSimultaneously: {[unowned self] gesture in gesture === self.anchoredMultiselectGesture}
        ),
      anchoredMultiselectGesture:
        GestureManager.ResponseCollection(
          begin: notMoving,
          receiveTouch: noPopoversOrToolbars,
          recognizeSimultaneously: {[unowned self] gesture in gesture === self.multiselectGesture}
        )
      ])
  }


  /**
  handleTap:

  :param: gesture UITapGestureRecognizer
  */
  func handleTap(gesture: UITapGestureRecognizer) {
    MSLogDebug("gesture: \(gesture.nametag), state: \(gesture.state)")
    if gesture.state == .Ended {
      if let tappedView = view.hitTest(gesture.locationInView(view), withEvent: nil) as? RemoteElementView{
        if sourceView.objectIsSubelementKind(tappedView) {
          if selectedViews ∌ tappedView { selectView(tappedView)}
          focusView = (focusView === tappedView ? nil : tappedView)
        }
      }
    }
  }

  /**
  handleLongPress:

  :param: gesture LongPressGesture
  */
  func handleLongPress(gesture: LongPressGesture) {
    MSLogDebug("gesture: \(gesture.nametag), state: \(gesture.state)")
    if gesture === longPressGesture {
      switch gesture.state {
        case .Began:
          if let pressedView = view.hitTest(gesture.locationInView(view), withEvent: nil) as? RemoteElementView {
            if sourceView.objectIsSubelementKind(pressedView) {
              if selectedViews ∌ pressedView { selectView(pressedView) }
              movingSelectedViews = true
              longPressPreviousLocation = gesture.locationInView(nil)
              willTranslateSelectedViews()
            }
          }
        case .Changed:
          let currentLocation = gesture.locationInView(nil)
          let translation = currentLocation - longPressPreviousLocation
          longPressPreviousLocation = currentLocation
          translateSelectedViews(translation)
        case .Cancelled, .Failed, .Ended:
          didTranslateSelectedViews()
        default: break
      }
    } else if gesture === toolbarLongPressGesture {
      switch gesture.state {
        case .Began:
          undoButton.button.setTitle(UIFont.fontAwesomeIconForName("repeat"), forState: .Normal)
          undoButton.button.selected = true
        case .Changed:
          if !undoButton.button.pointInside(gesture.locationInView(undoButton.button), withEvent: nil) {
            undoButton.button.selected = false
            gesture.enabled = false
          }
        case .Ended:
          redo(nil)
        default:
          gesture.enabled = true
          undoButton.button.selected = false
          undoButton.button.setTitle(UIFont.fontAwesomeIconForName("undo"), forState: .Normal)
      }
    }
  }

  /**
  handlePinch:

  :param: gesture UIPinchGestureRecognizer
  */
  func handlePinch(gesture: UIPinchGestureRecognizer) {
    MSLogDebug("gesture: \(gesture.nametag), state: \(gesture.state)")
    if gesture === pinchGesture {
      switch gesture.state {
        case .Began: willScaleSelectedViews()
        case .Changed: scaleSelectedViews(gesture.scale)
        case .Cancelled, .Failed, .Ended: didScaleSelectedViews()
        default: break
      }
    }
  }

  /**
  handlePan:

  :param: gesture UIPanGestureRecognizer
  */
  func handlePan(gesture: PanGesture) {
    //TODO: Get pan working with non-empty selection
    MSLogDebug("gesture: \(gesture.nametag), state: \(gesture.state)")
    if gesture === twoTouchPanGesture {
      switch gesture.state {
        case .Began:
          startingPanOffset = sourceViewCenterYConstraint.constant
        case .Changed:
          let translation = gesture.translationInView(view)
          let adjustedOffset = startingPanOffset + translation.y
          let isInBounds = allowableSourceViewYOffset.contains(adjustedOffset)
          let newOffset = (isInBounds
                           ? adjustedOffset
                           : (adjustedOffset < allowableSourceViewYOffset.start
                              ? allowableSourceViewYOffset.start
                              : allowableSourceViewYOffset.end))
          if sourceViewCenterYConstraint.constant != newOffset {
            UIView.animateWithDuration(0.1,
                                 delay: 0.0,
                               options: .BeginFromCurrentState,
                            animations: { self.sourceViewCenterYConstraint.constant = newOffset; self.view.layoutIfNeeded() },
                            completion: nil)
          }
        default: break
      }
    }
  }

  /**
  handleSelection:

  :param: gesture MultiselectGestureRecognizer
  */
  func handleSelection(gesture: MultiselectGestureRecognizer) {
    MSLogDebug("gesture: \(gesture.nametag), state: \(gesture.state)")
   if gesture.state == .Ended {
    let touchLocations = gesture.touchLocationsInView(sourceView)
    let touchedSubelementViews = gesture.touchedSubviewsInView(sourceView){self.sourceView.objectIsSubelementKind($0)}
    if touchedSubelementViews.count > 0 {

      let stackedViews = OrderedSet((sourceView.subelementViews as [RemoteElementView]).filter {
        v in contains(touchLocations, { v.pointInside(v.convertPoint($0, fromView: self.sourceView), withEvent: nil)})
        })

      if stackedViews.count > touchedSubelementViews.count { displayStackedViewDialogForViews(stackedViews) }

      if gesture === multiselectGesture { selectViews(OrderedSet(touchedSubelementViews.array as [RemoteElementView])) }
      else if gesture === anchoredMultiselectGesture { deselectViews(OrderedSet(touchedSubelementViews.array as [RemoteElementView])) }


     }

     else if selectedViews.count > 0 { deselectAll() }

   }

  }

}

/// MARK: - Translating subelements
////////////////////////////////////////////////////////////////////////////////
extension RemoteElementEditingController {

  /**
  Sanity check for ensuring selected views can only be moved to reasonable locations.

  :param: fromUnion `CGRect` representing the current union of the `frame` properties of the current selection
  :param: toUnion `CGRect` representing the resulting union of the `frame` properties of the current selection when moved

  :returns: Whether the views should be moved
  */
  func shouldTranslateSelectionFrom(fromUnion: CGRect, to toUnion: CGRect) -> Bool { return contentRect.contains(toUnion) }

  /**
  Captures the original union frame for the selected views before any translation and acts as an override point for subclasses
  to perform additional work pre-movement.
  */
  func willTranslateSelectedViews() { appliedTranslation = CGPoint.zeroPoint }

  /**
  Updates the `frame` property of the selected views to affect the specified translation.

  :param: translation `CGPoint` value representing the x and y axis translations to be performed on the selected views
  */
  func translateSelectedViews(translation: CGPoint) {
    if translation == CGPoint.zeroPoint { return }
    let transform = CGAffineTransform(tx: translation.x, ty: translation.y)
    let fromUnion = reduce(selectedViews, CGRect.nullRect){$0 ∪ $1.frame}
    let fromUnionInWindow = sourceView.convertRect(fromUnion, toView: nil)
    let toUnion = fromUnion.rectByApplyingTransform(transform)
    let toUnionInWindow = sourceView.convertRect(toUnion, toView: nil)
    let shouldTranslate = shouldTranslateSelectionFrom(fromUnionInWindow, to: toUnionInWindow)

    MSLogDebug("\n".join("translation = \(translation)",
                          "from union = \(fromUnion)",
                          "from union in window = \(fromUnionInWindow)",
                          "to union = \(toUnion)",
                          "to union in window = \(toUnionInWindow)",
                          "content rect = \(contentRect)",
                          "should translate? \(shouldTranslate)"))

    if shouldTranslate {
      UIView.animateWithDuration(0.1,
        delay: 0.0,
        options: .BeginFromCurrentState,
        animations: { for view in self.selectedViews { view.frame.transform(transform) } },
        completion: nil)

      appliedTranslation += translation
    }
  }

  /**
  Sends `translateSublements:translation:` to the `sourceView` to perform model-level translation and acts as an override point
  for subclasses to perform additional work post-movement.
   */
  func didTranslateSelectedViews() {
    MSLogDebug("")
    if appliedTranslation != CGPoint.zeroPoint { sourceView.translateSubelements(selectedViews, translation: appliedTranslation) }
    movingSelectedViews = false
  }

}

/// MARK: - Editing and adding subelements
////////////////////////////////////////////////////////////////////////////////
extension RemoteElementEditingController {

  /** addSubelement */
  func addSubelement() {
    let layout = UICollectionViewFlowLayout(scrollDirection: .Horizontal)
    let presetVC = REPresetCollectionViewController(collectionViewLayout: layout)
    presetVC.context = context
    addChildViewController(presetVC)
    let presetView = presetVC.collectionView
    presetView.constrain("'height' self.height = 0")
    view.addSubview(presetView)
    view.constrain("|[preset]| :: V:[preset]|", views: ["preset": presetView])
    view.layoutIfNeeded()
    UIView.transitionWithView(view, duration: 0.25, options: .CurveEaseInOut,
      animations: {
        if let c = presetView.constraintWithIdentifier("height") {
          c.constant = 200.0
          presetView.layoutIfNeeded()
        }
      },
      completion: {_ in self.presetsActive = true})
  }

  /** presets */
  func presets() { println(__FUNCTION__) }

  /** editBackground */
  func editBackground() {
     let bgEditor = BackgroundEditingController()
     bgEditor.subject = remoteElement
     presentViewController(bgEditor, animated: true, completion: nil)
  }

  /** editSubelement */
  func editSubelement() {
    if let subelementView = selectedViews.first {
      presentedSubelementView = subelementView
      let model = subelementView.model
      let size = subelementView.bounds.size
      let controller = RemoteElementEditingController.editingControllerForElement(model, size: size)
      controller.delegate = self
      transitioningDelegate = editingTransitioningDelegate
      controller.transitioningDelegate = editingTransitioningDelegate
      presentViewController(controller, animated: true, completion: nil)
    }
  }

  /** duplicate */
  func duplicate() { println(__FUNCTION__) }

  /** copyStyle */
  func copyStyle() { println(__FUNCTION__) }

  /** pasteStyle */
  func pasteStyle() { println(__FUNCTION__) }


}

/// MARK: - UIResponderStandardEditActions
////////////////////////////////////////////////////////////////////////////////
extension RemoteElementEditingController {

  /**
  undo:

  :param: sender AnyObject?
  */
  func undo(sender: AnyObject?) { context.performBlockAndWait { self.context.undo() } }

  /**
  redo:

  :param: sender AnyObject?
  */
  func redo(sender: AnyObject?) { context.performBlockAndWait { self.context.redo() } }

  /**
  copy:

  :param: sender AnyObject?
  */
  override func copy(sender: AnyObject?) { println(__FUNCTION__) }

  /**
  cut:

  :param: sender AnyObject?
  */
  override func cut(sender: AnyObject?) { println(__FUNCTION__) }

  /**
  delete:

  :param: sender AnyObject?
  */
  override func delete(sender: AnyObject?) {
    let elementsToDelete = selectedViews.map{$0.model}
    apply(selectedViews){$0.removeFromSuperview()}
    selectedViews.removeAll()
    focusView = nil
    context.performBlockAndWait {
      self.context.deleteObjects(NSSet(array: elementsToDelete))
      self.context.processPendingChanges()
    }
    sourceView.setNeedsUpdateConstraints()
    sourceView.updateConstraintsIfNeeded()
  }

  /**
  paste:

  :param: sender AnyObject?
  */
  override func paste(sender: AnyObject?) { println(__FUNCTION__) }

  /**
  select:

  :param: sender AnyObject?
  */
  override func select(sender: AnyObject?) { println(__FUNCTION__) }

  /**
  selectAll:

  :param: sender AnyObject?
  */
  override func selectAll(sender: AnyObject?) { println(__FUNCTION__) }

  /**
  toggleBoldface:

  :param: sender AnyObject?
  */
  override func toggleBoldface(sender: AnyObject?) { println(__FUNCTION__) }

  /**
  toggleItalics:

  :param: sender AnyObject?
  */
  override func toggleItalics(sender: AnyObject?) { println(__FUNCTION__) }

  /**
  toggleUnderline:

  :param: sender AnyObject?
  */
  override func toggleUnderline(sender: AnyObject?) { println(__FUNCTION__) }

}


/// MARK: - Toolbars
////////////////////////////////////////////////////////////////////////////////
extension RemoteElementEditingController {

  /** updateToolbarDisplayed */
  func updateToolbarDisplayed() {
    if selectedViews.count > 0 { currentToolbar = focusView != nil ? focusSelectionToolbar : nonEmptySelectionToolbar }
    else { currentToolbar = emptySelectionToolbar }
  }

  /** updateBarButtonItems */
  func updateBarButtonItems() {
    if movingSelectedViews { apply(singleSelButtons + anySelButtons + multiSelButtons){$0.enabled = false}}
    else { apply(anySelButtons){$0.enabled = true} }
    let multipleSelections = selectedViews.count > 1
    apply(singleSelButtons){$0.enabled = !multipleSelections}
    apply(multiSelButtons){$0.enabled = multipleSelections}
  }

}

/// MARK: - MSPopupBarButtonDelegate
////////////////////////////////////////////////////////////////////////////////
extension RemoteElementEditingController: MSPopupBarButtonDelegate {

  /**
  popupBarButtonDidShowPopover:

  :param: popupBarButton MSPopupBarButton
  */
  func popupBarButtonDidShowPopover(popupBarButton: MSPopupBarButton) { popoverActive = true}

  /**
  popupBarButtonDidHidePopover:

  :param: popupBarButton MSPopupBarButton
  */
  func popupBarButtonDidHidePopover(popupBarButton: MSPopupBarButton) { popoverActive = false}

}

/// MARK: - EditingDelegate
////////////////////////////////////////////////////////////////////////////////
extension RemoteElementEditingController: EditingDelegate {

  /**
  editorDidCancel:

  :param: editor RemoteElementEditingController
  */
  func editorDidCancel(editor: RemoteElementEditingController) {
    dismissViewControllerAnimated(true, completion: {self.presentedSubelementView = nil})
  }

  /**
  editorDidSave:

  :param: editor RemoteElementEditingController
  */
  func editorDidSave(editor: RemoteElementEditingController) {
    dismissViewControllerAnimated(true, completion: {self.presentedSubelementView = nil})
  }

}
