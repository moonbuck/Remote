//
//  CollectionManipulations.swift
//  MoonKit
//
//  Created by Jason Cardwell on 4/12/15.
//  Copyright (c) 2015 Jason Cardwell. All rights reserved.
//

import Foundation

/**
spliced:newElements:atIndex:

- parameter x: C
- parameter newElements: S
- parameter i: C.Index

- returns: C
*/
public func spliced<C : RangeReplaceableCollectionType, S : CollectionType
  where C.Generator.Element == S.Generator.Element>(x: C, newElements: S, atIndex i: C.Index) -> C
{
  var xPrime = x
  splice(&xPrime, newElements, atIndex: i)
  return xPrime
}

/**
removedAtIndex:index:

- parameter x: C
- parameter index: C.Index

- returns: C
*/
public func removedAtIndex<C : RangeReplaceableCollectionType>(x: C, index: C.Index) -> C {
  var xPrime = x
  removeAtIndex(&xPrime, index)
  return xPrime
}

public func valuesForKey<C: KeyValueCollectionType, K:Hashable, V where C.Key == K>(key: K, container: C) -> [V] {
  let containers: [C] = flattened(container)
  return compressedMap(containers) { $0[key] as? V }
}

