//
//  ActivityViewController.swift
//  Remote
//
//  Created by Jason Cardwell on 3/1/15.
//  Copyright (c) 2015 Moondeer Studios. All rights reserved.
//

import Foundation
import UIKit
import MoonKit
import DataModel
import Settings

public final class ActivityViewController: UIViewController {

  public static let proximitySensorKey = "RemoteProximitySensorKey"
  override public class func initialize() {
    if self === ActivityViewController.self {
      SettingsManager.registerSettingWithKey(proximitySensorKey,
                            withDefaultValue: true,
                                fromDefaults: {($0 as? NSNumber)?.boolValue == true},
                                  toDefaults: {$0})
    }
  }

  let controller: ActivityController
  
  private var remoteReceptionist: MSKVOReceptionist!
  private var settingsReceptionist: MSNotificationReceptionist!
  private weak var topToolbarView: ButtonGroupView!
  private weak var topToolbarConstraint: NSLayoutConstraint!
  private weak var remoteView: RemoteView!

  /**
  initWithController:

  :param: controller ActivityController
  */
  init(controller: ActivityController) {
    self.controller = controller
    super.init(nibName: nil, bundle: nil)

    remoteReceptionist = MSKVOReceptionist(observer: self,
      forObject: controller,
      keyPath: "currentRemote",
      options: .New,
      queue: NSOperationQueue.mainQueue(),
      handler: {
        if let remote = $0.change[NSKeyValueChangeNewKey] as? Remote,
          let viewController = $0.observer as? ActivityViewController {
            viewController.insertRemoteView(RemoteView(model: remote))
        }
    })

    settingsReceptionist = MSNotificationReceptionist(
      observer: self,
      forObject: SettingsManager.self,
      notificationName: SettingsManager.NotificationName,
      queue: NSOperationQueue.mainQueue(),
      handler: { _ in
        UIDevice.currentDevice().proximityMonitoringEnabled =
          SettingsManager.valueForSetting(ActivityViewController.proximitySensorKey) ?? false
    })
  }

  /**
  init:

  :param: aDecoder NSCoder
  */
  required public init(coder aDecoder: NSCoder) {
      fatalError("init(coder:) has not been implemented")
  }

  /** viewDidLoad */
  override public func viewDidLoad() {
    super.viewDidLoad()

    // Do any additional setup after loading the view.
    view.addGestureRecognizer(UIPinchGestureRecognizer(target: self, action: "handlePinch:"))

    let topToolbarView = ButtonGroupView(model: controller.topToolbar)
    view.addSubview(topToolbarView)
    self.topToolbarView = topToolbarView

    insertRemoteView(RemoteView(model: controller.currentRemote))
  }

  /**
  viewWillAppear:

  :param: animated Bool
  */
  override public func viewWillAppear(animated: Bool) {
    super.viewWillAppear(animated)
    if SettingsManager.valueForSetting(ActivityViewController.proximitySensorKey) == true {
      UIDevice.currentDevice().proximityMonitoringEnabled = true
    }
  }

  /**
  viewWillDisappear:

  :param: animated Bool
  */
  override public func viewWillDisappear(animated: Bool) {
    super.viewWillDisappear(animated)
    if SettingsManager.valueForSetting(ActivityViewController.proximitySensorKey) == true {
      UIDevice.currentDevice().proximityMonitoringEnabled = false
    }
  }

  /** updateTopToolbarLocation */
  func updateTopToolbarLocation() {
    if controller.currentRemote.topBarHidden == (topToolbarConstraint.constant == 0) { toggleTopToolbar(true) }
  }

  /**
  viewDidAppear:

  :param: animated Bool
  */
  override public func viewDidAppear(animated: Bool) {
    super.viewDidAppear(animated)
    updateTopToolbarLocation()
  }

  /**
  handlePinch:

  :param: pinch UIPinchGestureRecognizer
  */
  func handlePinch(pinch: UIPinchGestureRecognizer) { if pinch.state == .Ended { toggleTopToolbar(true)} }

  /**
  toggleTopToolbar:

  :param: animated Bool
  */
  func toggleTopToolbar(animated: Bool) {
    let constant = topToolbarConstraint.constant > 0.0 ? 0.0 : -topToolbarView.bounds.height
    if animated { animateToolbar(constant) } else { topToolbarConstraint.constant = constant }
  }

  /**
  animateToolbar:

  :param: constraintConstant CGFloat
  */
  func animateToolbar(constraintConstant: CGFloat) {
    UIView.animateWithDuration(0.25,
      delay: 0.0,
      options: .BeginFromCurrentState,
      animations: {self.topToolbarConstraint.constant = constraintConstant; self.view.layoutIfNeeded()},
      completion: nil)
  }

  /**
  showTopToolbar:

  :param: animated Bool
  */
  func showTopToolbar(animated: Bool) { if animated { animateToolbar(0.0) } else { topToolbarConstraint.constant = 0.0 } }

  /**
  hideTopToolbar:

  :param: animated Bool
  */
  func hideTopToolbar(animated: Bool) {
    if animated { animateToolbar(-topToolbarView.bounds.height) }
    else { topToolbarConstraint.constant = -topToolbarView.bounds.height }
  }

  /**
  insertRemoteView:

  :param: remoteView RemoteView
  */
  func insertRemoteView(remoteView: RemoteView) {
    if self.remoteView != nil {
      UIView.animateWithDuration(0.25, animations: {
        self.remoteView.removeFromSuperview()
        self.view.insertSubview(remoteView, belowSubview: self.topToolbarView)
        self.remoteView = remoteView
        self.view.setNeedsUpdateConstraints()
      })
    } else {
      view.insertSubview(remoteView, belowSubview: topToolbarView)
      self.remoteView = remoteView
      view.setNeedsUpdateConstraints()
    }
  }

  /** updateViewConstraints */
  override public func updateViewConstraints() {
    super.updateViewConstraints()
    let identifier = createIdentifier(self, "Internal")

    view.removeConstraintsWithIdentifier(identifier)

    if remoteView != nil && topToolbarView != nil {
      let format = "\n".join(
        "remote.centerX = self.centerX",
        "remote.bottom = self.bottom",
        "remote.top = self.top",
        "toolbar.centerX = self.centerX"
      )
      view.constrain(format, views: ["remote": remoteView, "toolbar": topToolbarView], identifier: identifier)
    }

    let topToolbarConstraint = NSLayoutConstraint(item: topToolbarView,
                                                  attribute: .Top,
                                                  relatedBy: .Equal,
                                                  toItem: view,
                                                  attribute: .Top,
                                                  multiplier: 1.0,
                                                  constant: 0.0)

    view.addConstraint(topToolbarConstraint)
    self.topToolbarConstraint = topToolbarConstraint

    updateTopToolbarLocation()

  }

}