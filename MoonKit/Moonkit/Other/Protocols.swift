//
//  Protocols.swift
//  MSKit
//
//  Created by Jason Cardwell on 11/17/14.
//  Copyright (c) 2014 Jason Cardwell. All rights reserved.
//

import Foundation

public protocol JSONValueConvertible {
  var jsonValue: JSONValue { get }
}

public protocol JSONValueInitializable {
  init?(_ jsonValue: JSONValue?)
}

public protocol JSONExport {
  var jsonString: String { get }
}

public protocol KeyValueCollectionType: CollectionType {
  typealias Key: Hashable
  typealias Value
  subscript (key: Key) -> Value? { get }
  typealias KeysLazyCollectionType: CollectionType
  typealias ValuesLazyCollectionType: CollectionType
  var keys: LazyForwardCollection<KeysLazyCollectionType> { get }
  var values: LazyForwardCollection<ValuesLazyCollectionType> { get }
}

extension Dictionary: KeyValueCollectionType {}

public func valuesForKey<C: KeyValueCollectionType, K:Hashable, V where C.Key == K>(key: K, container: C) -> [V] {
  var containers: [C] = flattened(container)
  return compressedMap(containers) { $0[key] as? V }
}

public protocol Presentable {
  var title: String { get }
}

public protocol Divisible {
  func /(lhs: Self, rhs: Self) -> Self
}

public protocol EnumerableType {
  static func enumerate(block: (Self) -> Void)
  static var all: [Self] { get }
}

// causes ambiguity
public protocol IntegerDivisible {
  func /(lhs: Self, rhs:Int) -> Self
}

public protocol Summable {
  func +(lhs: Self, rhs: Self) -> Self
}

public protocol OptionalSubscriptingCollectionType: CollectionType {
  subscript (position: Optional<Self.Index>) -> Self.Generator.Element? { get }
}

public protocol Unpackable2 {
  typealias Element
  func unpack() -> (Element, Element)
}

public protocol Unpackable3 {
  typealias Element
  func unpack() -> (Element, Element, Element)
}

public protocol Unpackable4 {
  typealias Element
  func unpack() -> (Element, Element, Element, Element)
}

/** Protocol for an object guaranteed to have a name */
@objc public protocol Named {
  var name: String { get }
}

@objc public protocol DynamicallyNamed: Named {
  var name: String { get set }
}

/** Protocol for an object that may have a name */
@objc public protocol Nameable {
  var name: String? { get }
}

/** Protocol for an object that may have a name and for which a name may be set */
@objc public protocol Renameable: Nameable {
  var name: String? { get set }
}

public protocol StringValueConvertible {
  var stringValue: String { get }
}

/**
sortedByName:

:param: seq S

:returns: [S.Generator.Element]
*/
public func sortedByName<S:SequenceType where S.Generator.Element:Nameable>(seq: S) -> [S.Generator.Element] { return Array(seq).sorted{$0.0.name < $0.1.name} }

/**
sortedByName:

:param: seq S?

:returns: [S.Generator.Element]?
*/
public func sortedByName<S:SequenceType where S.Generator.Element:Nameable>(seq: S?) -> [S.Generator.Element]? {
  if seq != nil {  return Array(seq!).sorted{$0.0.name < $0.1.name} } else { return nil }
}

/**
sortByName:

:param: array [T]
*/
public func sortByName<T: Nameable>(inout array: [T]) { array.sort{$0.0.name < $0.1.name} }

/**
sortByName:

:param: array [T]?
*/
public func sortByName<T: Nameable>(inout array: [T]?) { array?.sort{$0.0.name < $0.1.name} }

/**
sortedByName:

:param: seq S

:returns: [S.Generator.Element]
*/
public func sortedByName<S:SequenceType where S.Generator.Element:Named>(seq: S) -> [S.Generator.Element] { return Array(seq).sorted{$0.0.name < $0.1.name} }

/**
sortedByName:

:param: seq S?

:returns: [S.Generator.Element]?
*/
public func sortedByName<S:SequenceType where S.Generator.Element:Named>(seq: S?) -> [S.Generator.Element]? {
  if seq != nil {  return Array(seq!).sorted{$0.0.name < $0.1.name} } else { return nil }
}

/**
sortByName:

:param: array [T]
*/
public func sortByName<T: Named>(inout array: [T]) { array.sort{$0.0.name < $0.1.name} }

/**
sortByName:

:param: array [T]?
*/
public func sortByName<T: Named>(inout array: [T]?) { array?.sort{$0.0.name < $0.1.name} }
