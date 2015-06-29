//
//  OrderedSet.swift
//  MSKit
//
//  Created by Jason Cardwell on 10/28/14.
//  Copyright (c) 2014 Jason Cardwell. All rights reserved.
//

import Foundation

public struct OrderedSet<T:Equatable> : MutableCollectionType, Sliceable {

  private var storage: [T] {
    didSet {
      var s: [T] = []
      for e in storage { if !s.contains(e) { s.append(e) } }
      storage = s
    }
  }

  public typealias Element = T

  public var startIndex: Int { return storage.startIndex }
  public var endIndex: Int { return storage.endIndex }

  /**
  subscript:

  - parameter index: Int

  - returns: T
  */
  public subscript (index: Int) -> T {
    get { return storage[index] }
    set { if !storage.contains(newValue) { storage[index] = newValue } }
  }

  /**
  generate

  - returns: IndexingGenerator<[T]>
  */
  public func generate() -> IndexingGenerator<[T]> { return storage.generate() }

  public typealias SubSlice = ArraySlice<T>

  /**
  subscript:

  - parameter subRange: Range<Int>

  - returns: Slice<T>
  */
  public subscript (subRange: Range<Int>) -> ArraySlice<T> { return storage[subRange] }

  /**
  init:

  - parameter buffer: _ArrayBuffer<T>
  */
  public init(_ buffer: _ArrayBuffer<T>) { storage = uniqued([T](buffer)) }


  /** init */
  public init() { storage = [] }

  /**
  init:

  - parameter s: S
  */
  public init<S : SequenceType where S.Generator.Element == T>(_ s: S) { storage = uniqued([T](s)) }

  public var count: Int      { return storage.count    }
  public var capacity: Int   { return storage.capacity }
  public var isEmpty: Bool   { return storage.isEmpty  }
  public var first: T?       { return storage.first    }
  public var last: T?        { return storage.last     }
  public var array: [T]      { return storage          }
  public var bridgedValue: NSOrderedSet? { return NSOrderedSet(array: storage._bridgeToObjectiveC() as [AnyObject]) }
  public var NSArrayValue: NSArray? {
    var elements: [NSObject] = []
    for element in storage {
      if let e = element as? NSObject {
        elements.append(e)
      }
    }
    return elements.count == storage.count ? NSArray(array: elements) : nil
  }

  public var NSSetValue: NSSet? { if let array = NSArrayValue { return NSSet(array: array as [AnyObject]) } else { return nil } }

  public var NSOrderedSetValue: NSOrderedSet? { if let array = NSArrayValue { return NSOrderedSet(array: array as [AnyObject]) } else { return nil } }

  /**
  reserveCapacity:

  - parameter minimumCapacity: Int
  */
  public mutating func reserveCapacity(minimumCapacity: Int) { storage.reserveCapacity(minimumCapacity) }

  /**
  append:

  - parameter newElement: T
  */
  public mutating func append(newElement: T) { if !storage.contains(newElement) { storage.append(newElement) } }

  /**
  extend:

  - parameter elements: S
  */
  public mutating func extend<S : SequenceType where S.Generator.Element == T>(elements: S) {
    storage.extend(Array(elements).filter { !self.storage.contains($0) })
  }

  /**
  removeLast

  - returns: T
  */
  public mutating func removeLast() -> T { return storage.removeLast() }

  /**
  insert:atIndex:

  - parameter newElement: T
  - parameter i: Int
  */
  public mutating func insert(newElement: T, atIndex i: Int) {
    if !storage.contains(newElement) { storage.insert(newElement, atIndex: i) }
  }

  /**
  removeAtIndex:

  - parameter index: Int

  - returns: T
  */
  public mutating func removeAtIndex(index: Int) -> T { return storage.removeAtIndex(index) }

  /**
  removeAll:

  - parameter keepCapacity: Bool = false
  */
  public mutating func removeAll(keepCapacity: Bool = false) { storage.removeAll(keepCapacity: keepCapacity) }

  /**
  join:

  - parameter elements: S

  - returns: [T]
  */
  public func join<S : SequenceType where S.Generator.Element == T>(elements: S) -> [T] {
    let elementsArray = Array(elements)
    let currentArray = storage
    return uniqued(elementsArray + currentArray)
  }

  /**
  reduce:combine:

  - parameter initial: U
  - parameter combine: (U, T) -> U

  - returns: U
  */
  public func reduce<U>(initial: U, combine: (U, T) -> U) -> U { return storage.reduce(initial, combine: combine) }

  /**
  sort:

  - parameter isOrderedBefore:  (T, T) -> Bool
  */
  public mutating func sort(isOrderedBefore:  (T, T) -> Bool) { storage.sortInPlace(isOrderedBefore) }

  /**
  sorted:

  - parameter isOrderedBefore: (T, T) -> Bool

  - returns: [T]
  */
  public func sorted(isOrderedBefore: (T, T) -> Bool) -> OrderedSet<T> { return OrderedSet(storage.sort(isOrderedBefore)) }

  /**
  map:

  - parameter transform: (T) -> U

  - returns: [U]
  */
  public func map<U: Equatable>(transform: (T) -> U) -> OrderedSet<U> { return OrderedSet<U>(storage.map(transform)) }

  /**
  reverse

  - returns: [T]
  */
  public func reverse() -> OrderedSet<T> { return OrderedSet(Array(storage.reverse())) }

  /**
  filter:

  - parameter includeElement: (T) -> Bool

  - returns: [T]
  */
  public func filter(includeElement: (T) -> Bool) -> OrderedSet<T> { return OrderedSet<T>(storage.filter(includeElement)) }

  /**
  replaceRange:with:

  - parameter subRange: Range<Int>
  - parameter elements: C
  */
  public mutating func replaceRange<C : CollectionType where C.Generator.Element == T>(subRange: Range<Int>, with elements: C) {
    var s = storage
    s.replaceRange(subRange, with: elements)
    storage = s
  }

  /**
  splice:atIndex:

  - parameter elements: S
  - parameter i: Int
  */
  public mutating func splice<S : CollectionType where S.Generator.Element == T>(elements: S, atIndex i: Int) {
    var s = storage
    s.splice(elements, atIndex: i)
    storage = s
  }

  /**
  removeRange:

  - parameter subRange: Range<Int>
  */
  public mutating func removeRange(subRange: Range<Int>) { storage.removeRange(subRange) }


}

extension OrderedSet : ArrayLiteralConvertible {

  /**
  init:

  - parameter elements: T...
  */
  public init(arrayLiteral elements: T...) { storage = elements }

}

extension OrderedSet : CustomStringConvertible, CustomDebugStringConvertible {
  public var description: String { return storage.description }
  public var debugDescription: String { return storage.debugDescription }
}

// MARK: _ObjectiveBridgeable
extension OrderedSet: _ObjectiveCBridgeable {
  static public func _isBridgedToObjectiveC() -> Bool {
    return true
  }
  public typealias _ObjectiveCType = NSOrderedSet
  static public func _getObjectiveCType() -> Any.Type { return _ObjectiveCType.self }
  public func _bridgeToObjectiveC() -> _ObjectiveCType {
    var objects: [AnyObject] = []
    for object in storage {
      if object is AnyObject {
        objects.append(object as! AnyObject)
      }
    }
    if objects.count == self.count {
      return NSOrderedSet(array: objects)
    } else {
      return NSOrderedSet()
    }
  }

  static public func _forceBridgeFromObjectiveC(source: NSOrderedSet, inout result: OrderedSet?) {
    var s = OrderedSet()
    for o in source {
      if let object = typeCast(o, T.self) { s.append(object) }
    }
    if s.count == source.count {
      result = s
    }
  }
  static public func _conditionallyBridgeFromObjectiveC(source: NSOrderedSet, inout result: OrderedSet?) -> Bool {
    var s = OrderedSet()
    for o in source {
      if let object = typeCast(o, T.self) { s.append(object) }
    }
    if s.count == source.count {
      result = s
      return true
    }
    return false
  }
}

extension OrderedSet : Equatable {}

/**
subscript:rhs:

- parameter lhs: OrderedSet<T>
- parameter rhs: OrderedSet<T>

- returns: Bool
*/
public func ==<T>(lhs: OrderedSet<T>, rhs: OrderedSet<T>) -> Bool { return lhs.storage == rhs.storage }

/**
subscript:rhs:

- parameter lhs: OrderedSet<T>
- parameter rhs: S

- returns: OrderedSet<T>
*/
public func +<T:Equatable, S:SequenceType where S.Generator.Element == T>(lhs: OrderedSet<T>, rhs: S) -> OrderedSet<T> {
  var orderedSet = lhs
  orderedSet.extend(rhs)
  return orderedSet
}

/**
subscript:rhs:

- parameter lhs: OrderedSet<T>
- parameter rhs: S
*/
public func +=<T:Equatable, S:SequenceType where S.Generator.Element == T>(inout lhs: OrderedSet<T>, rhs: S) { lhs.extend(rhs) }

/**
Union set operator

- parameter lhs: OrderedSet<T>
- parameter rhs: OrderedSet<T>
- returns: OrderedSet<T>
*/
public func ∪<T:Equatable, S:SequenceType where S.Generator.Element == T>(lhs: OrderedSet<T>, rhs: S) -> OrderedSet<T> {
  return lhs + rhs
}

/**
Union set operator which stores result in lhs

- parameter lhs: OrderedSet<T>
- parameter rhs: OrderedSet<T>
*/
public func ∪=<T:Equatable, S:SequenceType where S.Generator.Element == T>(inout lhs: OrderedSet<T>, rhs: S) { lhs += rhs }

/**
Minus set operator

- parameter lhs: OrderedSet<T>
- parameter rhs: OrderedSet<T>
- returns: OrderedSet<T>
*/
public func ∖<T:Equatable, S:SequenceType where S.Generator.Element == T>(lhs: OrderedSet<T>, rhs: S) -> OrderedSet<T> {
  return OrderedSet<T>(lhs.filter { $0 ∉ rhs })
}

/**
Minus set operator which stores result in lhs

- parameter lhs: OrderedSet<T>
- parameter rhs: OrderedSet<T>
*/
public func ∖=<T:Equatable, S:SequenceType where S.Generator.Element == T>(inout lhs: OrderedSet<T>, rhs: S) {
  lhs = lhs.filter { $0 ∉ rhs }
}

/**
Intersection set operator

- parameter lhs: OrderedSet<T>
- parameter rhs: OrderedSet<T>
- returns: OrderedSet<T>
*/
public func ∩<T:Equatable, S:SequenceType where S.Generator.Element == T>(lhs: OrderedSet<T>, rhs: S) -> OrderedSet<T> {
  return (lhs ∪ rhs).filter{$0 ∈ lhs && $0 ∈ rhs}
}


/**
Intersection set operator which stores result in lhs

- parameter lhs: OrderedSet<T>
- parameter rhs: OrderedSet<T>
*/
public func ∩=<T:Equatable, S:SequenceType where S.Generator.Element == T>(inout lhs: OrderedSet<T>, rhs: S) { lhs = lhs ∩ rhs }

/**
Returns true if lhs is a subset of rhs

- parameter lhs: OrderedSet<T>
- parameter rhs: OrderedSet<T>
- returns: Bool
*/
public func ⊂<T:Equatable, S:SequenceType where S.Generator.Element == T>(lhs: OrderedSet<T>, rhs: S) -> Bool { return lhs.filter {$0 ∉ rhs}.isEmpty }

/**
Returns true if lhs is not a subset of rhs

- parameter lhs: OrderedSet<T>
- parameter rhs: OrderedSet<T>
- returns: Bool
*/
public func ⊄<T:Equatable, S:SequenceType where S.Generator.Element == T>(lhs: OrderedSet<T>, rhs: S) -> Bool { return !(lhs ⊂ rhs) }

/**
Returns true if rhs is a subset of lhs

- parameter lhs: OrderedSet<T>
- parameter rhs: OrderedSet<T>
- returns: Bool
*/
public func ⊃<T:Equatable, S:SequenceType where S.Generator.Element == T>(lhs: OrderedSet<T>, rhs: S) -> Bool { return Array(rhs) ⊂ lhs.array }

/**
Returns true if rhs is not a subset of lhs

- parameter lhs: OrderedSet<T>
- parameter rhs: OrderedSet<T>
- returns: Bool
*/
public func ⊅<T:Equatable, S:SequenceType where S.Generator.Element == T>(lhs: OrderedSet<T>, rhs: S) -> Bool { return !(lhs ⊃ rhs) }

/**
Returns true if rhs contains lhs

- parameter lhs: T
- parameter rhs: T
- returns: Bool
*/
public func ∈<T:Equatable>(lhs: T, rhs: OrderedSet<T>) -> Bool { return rhs.contains(lhs) }
public func ∈<T:Equatable>(lhs: T?, rhs: OrderedSet<T>) -> Bool { return lhs != nil && rhs.contains(lhs!) }

/**
Returns true if lhs contains rhs

- parameter lhs: T
- parameter rhs: T
- returns: Bool
*/
public func ∋<T:Equatable>(lhs: OrderedSet<T>, rhs: T) -> Bool { return rhs ∈ lhs }

/**
Returns true if rhs does not contain lhs

- parameter lhs: T
- parameter rhs: T
- returns: Bool
*/
public func ∉<T:Equatable>(lhs: T, rhs: OrderedSet<T>) -> Bool { return !(lhs ∈ rhs) }

/**
Returns true if lhs does not contain rhs

- parameter lhs: T
- parameter rhs: T
- returns: Bool
*/
public func ∌<T:Equatable>(lhs: OrderedSet<T>, rhs: T) -> Bool { return !(lhs ∋ rhs) }

extension OrderedSet: NestingContainer {
  public var topLevelObjects: [Any] {
    var result: [Any] = []
    for value in self {
      result.append(value as Any)
    }
    return result
  }
  public func topLevelObjects<T>(type: T.Type) -> [T] {
    var result: [T] = []
    for value in self {
      if let v = value as? T {
        result.append(v)
      }
    }
    return result
  }
  public var allObjects: [Any] {
    var result: [Any] = []
    for value in self {
      if let container = value as? NestingContainer {
        result.extend(container.allObjects)
      } else {
        result.append(value as Any)
      }
    }
    return result
  }
  public func allObjects<T>(type: T.Type) -> [T] {
    var result: [T] = []
    for value in self {
      if let container = value as? NestingContainer {
        result.extend(container.allObjects(type))
      } else if let v = value as? T {
        result.append(v)
      }
    }
    return result
  }
}

extension OrderedSet: KeySearchable {
  public var allValues: [Any] { return topLevelObjects }
}
