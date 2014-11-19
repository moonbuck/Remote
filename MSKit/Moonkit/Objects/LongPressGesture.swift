//
//  LongPressGesture.swift
//  MSKit
//
//  Created by Jason Cardwell on 11/18/14.
//  Copyright (c) 2014 Jason Cardwell. All rights reserved.
//

import Foundation
import UIKit
import UIKit.UIGestureRecognizerSubclass


public class LongPressGesture: BlockActionGesture {

  /// MARK: - Mimicking UILongPressGestureRecognizer
  ////////////////////////////////////////////////////////////////////////////////

  /** The number of full taps required before the press for gesture to be recognized */
  public var numberOfTapsRequired: Int = 0

  /** Number of fingers that must be held down for the gesture to be recognized */
  public var numberOfTouchesRequired: Int = 1

  /** Time in seconds the fingers must be held down for the gesture to be recognized */
  public var minimumPressDuration = 0.5

  /**
  Maximum movement in pixels allowed before the gesture fails. Once recognized (after minimumPressDuration)
  there is no limit on finger movement for the remainder of the touch tracking
  */
  public var allowableMovement: CGFloat = 10.0

  /// MARK: -

  private var centroid: CGPoint = CGPoint.nullPoint
  private var pressingTouches: OrderedSet<UITouch> = [] { didSet { centroid = centroidForTouches(pressingTouches.array)} }
  private var pressTimestamp: Double = 0.0 {
    didSet {
      if pressTimestamp > 0.0 {
        let seconds = Int64(minimumPressDuration * Double(NSEC_PER_SEC))
        let when = dispatch_time(DISPATCH_TIME_NOW, seconds)
        dispatch_after(when, dispatch_get_main_queue()) {
          [unowned self] () -> Void in
            if (self.pressingTouches.filter{$0.phase == UITouchPhase.Stationary}).count == self.numberOfTouchesRequired {
              self.pressRecognized = true
              self.state = .Changed
          }
        }
      }
    }
  }
  public private(set) var pressRecognized: Bool = false

 /** reset */
  public override func reset() {
    state = .Possible
    pressingTouches.removeAll()
    pressTimestamp = 0.0
    pressRecognized = false
    centroid = CGPoint.nullPoint
  }

  /**
  touchesBegan:withEvent:

  :param: touches NSSet
  :param: event UIEvent
  */
  public override func touchesBegan(touches: NSSet, withEvent event: UIEvent) {
    if pressingTouches.count == 0 {
      let beginningTouches = touches.allObjects as [UITouch]
      if beginningTouches.count == numberOfTouchesRequired {
        if (beginningTouches.filter{$0.tapCount >= self.numberOfTapsRequired}).count == beginningTouches.count {
          pressingTouches = OrderedSet(beginningTouches)
          pressTimestamp = pressingTouches.reduce(0.0, combine: {$0 + $1.timestamp}) / Double(pressingTouches.count)
          state = .Began
        }
      }
    }

    if state != .Began { state = .Failed }
  }

  /**
  touchesMoved:withEvent:

  :param: touches NSSet
  :param: event UIEvent
  */
  public override func touchesMoved(touches: NSSet, withEvent event: UIEvent) {
    if pressingTouches ⊃ (touches.allObjects as [UITouch]) {
      if !pressRecognized {
        assert(centroid != CGPoint.nullPoint, "why haven't we calculated a centroid for the beginning state?")
        let currentCentroid = centroidForTouches(pressingTouches.array)
        let delta = (currentCentroid - centroid).absolute
        let movement = max(delta.x, delta.y)
        if movement > allowableMovement { state = .Failed }
        else { state = .Changed }
      }
      else { state = .Changed }
    } else { assertionFailure("received touches should be members of pressingTouches set") }
  }

  /**
  touchesCancelled:withEvent:

  :param: touches NSSet
  :param: event UIEvent
  */
  public override func touchesCancelled(touches: NSSet, withEvent event: UIEvent) {
    if pressingTouches ⊃ (touches.allObjects as [UITouch]) {
      state = .Cancelled
    } else { assertionFailure("received touches should be members of pressingTouches set") }
  }

  /**
  touchesEnded:withEvent:

  :param: touches NSSet
  :param: event UIEvent
  */
  public override func touchesEnded(touches: NSSet, withEvent event: UIEvent) {
    if pressingTouches ⊃ (touches.allObjects as [UITouch]) {
      state = pressRecognized ? .Ended : .Failed
    } else { assertionFailure("received touches should be members of pressingTouches set") }
  }

}
