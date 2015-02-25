//
//  Protocols.swift
//  MSKit
//
//  Created by Jason Cardwell on 11/17/14.
//  Copyright (c) 2014 Jason Cardwell. All rights reserved.
//

import Foundation

public protocol JSONValueConvertible {
  typealias JSONValueType
  var JSONValue: JSONValueType { get }
  init?(JSONValue: JSONValueType)
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
