//
//  Array+MoonKitAdditions.swift
//  HomeRemote
//
//  Created by Jason Cardwell on 8/9/14.
//  Copyright (c) 2014 Moondeer Studios. All rights reserved.
//

import Foundation

public extension Array {
  public mutating func replaceAll(value:Element) { for i in 0..<count { self[i] = value } }

  public mutating func apply(block:(Element) -> Void) { reduce(Void()){block($0.1)} }
  /**
  findFirst:

  :param: matchElement (Element)->Bool

  :returns: Element?
  */
  public func findFirst(matchElement:(Element)->Bool) -> Element? { return filter(matchElement).first }

}

