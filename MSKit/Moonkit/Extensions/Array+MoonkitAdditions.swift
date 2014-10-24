//
//  Array+MoonKitAdditions.swift
//  HomeRemote
//
//  Created by Jason Cardwell on 8/9/14.
//  Copyright (c) 2014 Moondeer Studios. All rights reserved.
//

import Foundation

extension Array {

  /**
  replaceAll:

  :param: value Element
  */
  mutating func replaceAll(value:Element) { for i in 0..<count { self[i] = value } }

  /**
  apply:

  :param: block (Element) -> Void
  */
  func apply(block:(Element) -> Void) { reduce(Void()){block($0.1)} }

  /**
  findFirst:

  :param: matchElement (Element)->Bool

  :returns: Element?
  */
  func findFirst(matchElement:(Element)->Bool) -> Element? { return filter(matchElement).first }

}

public extension NSArray {

  func apply(block:(AnyObject) -> Void) {
    enumerateObjectsUsingBlock { (obj, idx, stop) -> Void in
      block(obj)
    }
  }

}