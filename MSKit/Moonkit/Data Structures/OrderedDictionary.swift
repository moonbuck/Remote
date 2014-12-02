//
//  OrderedDictionary.swift
//  HomeRemote
//
//  Created by Jason Cardwell on 8/7/14.
//  Copyright (c) 2014 Moondeer Studios. All rights reserved.
//

import Foundation

public struct OrderedDictionary<Key : Hashable, Value> : CollectionType {
  public typealias KeyType = Key
  public typealias ValueType = Value
  public typealias Element = (KeyType, ValueType)
  public typealias Index = DictionaryIndex<KeyType, ValueType>

  private var storage: [KeyType:ValueType]
  private var indexKeys: [KeyType]
  private var printableKeys = false

  public var userInfo: [String:AnyObject]?
  public var count: Int { return indexKeys.count }
  public var isEmpty: Bool { return indexKeys.isEmpty }
  public var keys: [KeyType] { return indexKeys }
  public var values: [ValueType] { return indexKeys.map { self.storage[$0]! } }


  ////////////////////////////////////////////////////////////////////////////////
  /// MARK: - Initializers
  ////////////////////////////////////////////////////////////////////////////////


  /**
  initWithMinimumCapacity:

  :param: minimumCapacity Int = 4
  */
  public init(minimumCapacity: Int = 4) {
    storage = [KeyType:ValueType](minimumCapacity: minimumCapacity)
    indexKeys = [KeyType]()
    indexKeys.reserveCapacity(minimumCapacity)
  }

  /**
  initWithMinimumCapacity:

  :param: minimumCapacity Int = 4
  */
  public init<K,V where K:Printable>(minimumCapacity: Int = 4) {
    storage = [KeyType:ValueType](minimumCapacity: minimumCapacity)
    indexKeys = [KeyType]()
    indexKeys.reserveCapacity(minimumCapacity)
    printableKeys = true
  }

  /**
  init:

  :param: dict NSDictionary
  */
  public init(_ dict: NSDictionary) { self.init(dict as [NSObject:AnyObject]) }

  /**
  init:

  :param: dict [KeyType
  */
  public init(_ dict:[KeyType:ValueType]) {
    storage = dict
    indexKeys = Array(dict.keys)
    printableKeys = true
  }

  /**
  initWithKeys:values:

  :param: keys [KeyType]
  :param: values [ValueType]
  */
  public init(keys:[KeyType], values:[ValueType]) {
    self.init(minimumCapacity: keys.count)
    if keys.count == values.count {
      indexKeys += keys
      for i in 0..<keys.count { let k = keys[i]; let v = values[i]; storage[k] = v }
    }
  }

  /**
  fromMSDictionary:

  :param: msdict MSDictionary

  :returns: OrderedDictionary<NSObject, AnyObject>
  */
  public static func fromMSDictionary(msdict: MSDictionary) -> OrderedDictionary<NSObject, AnyObject> {
    var orderedDict = OrderedDictionary<NSObject,AnyObject>(minimumCapacity: 4)

    let keys = msdict.allKeys as [NSObject]
    let values = msdict.allValues as [AnyObject]

    for i in 0..<keys.count {
      let k = keys[i]
      let v: AnyObject = values[i]
      orderedDict.setValue(v, forKey: k)
    }

    return orderedDict
  }

  ////////////////////////////////////////////////////////////////////////////////
  /// MARK: - Indexes
  ////////////////////////////////////////////////////////////////////////////////


  public var startIndex: DictionaryIndex<KeyType, ValueType> { return storage.indexForKey(indexKeys[0])! }
  public var endIndex: DictionaryIndex<KeyType, ValueType> { return storage.indexForKey(indexKeys.last!)! }

  /**
  indexForKey:

  :param: key KeyType

  :returns: DictionaryIndex<KeyType, ValueType>?
  */
  public func indexForKey(key: KeyType) -> DictionaryIndex<KeyType, ValueType>? { return storage.indexForKey(key) }

  /**
  subscript:

  :param: key KeyType

  :returns: ValueType?
  */
  public subscript (key: KeyType) -> ValueType? { get { return storage[key] } set { setValue(newValue, forKey: key) } }

  /**
  subscript:ValueType>:

  :param: i DictionaryIndex<KeyType
  :param: ValueType>

  :returns: (KeyType, ValueType)
  */
  public subscript (i: DictionaryIndex<KeyType, ValueType>) -> (KeyType, ValueType) { return storage[i] }


  ////////////////////////////////////////////////////////////////////////////////
  /// MARK: - Updating and removing values
  ////////////////////////////////////////////////////////////////////////////////

  /**
  setValue:forKey:

  :param: value ValueType
  :param: key KeyType
  */
  public mutating func setValue(value: ValueType?, forKey key: KeyType) {
    if let v = value {
      if !contains(indexKeys, key) { indexKeys.append(key) }
      storage[key] = value
    } else {
      if let idx = find(indexKeys, key) { indexKeys.removeAtIndex(idx) }
      storage[key] = nil
    }
  }

  /**
  updateValue:forKey:

  :param: value ValueType
  :param: key KeyType

  :returns: ValueType?
  */
  public mutating func updateValue(value: ValueType, forKey key: KeyType) -> ValueType? {
    let currentValue: ValueType? = contains(indexKeys, key) ? storage[key] : nil
    if !contains(indexKeys, key) { indexKeys.append(key) }
    storage[key] = value
    return currentValue
  }

  /**
  removeAtIndex:ValueType>:

  :param: index DictionaryIndex<KeyType
  :param: ValueType>
  */
  public mutating func removeAtIndex(index: DictionaryIndex<KeyType, ValueType>) {
    let (k, _) = self[index]
    indexKeys.removeAtIndex(find(indexKeys, k)!)
    storage.removeAtIndex(index)
  }

  /**
  removeValueForKey:

  :param: key KeyType

  :returns: ValueType?
  */
  public mutating func removeValueForKey(key: KeyType) -> ValueType? {
    if let idx = find(indexKeys, key) {
      indexKeys.removeAtIndex(idx)
      return storage.removeValueForKey(key)
    } else {
      return nil
    }
  }

  /**
  removeAll:

  :param: keepCapacity Bool = false
  */
  public mutating func removeAll(keepCapacity: Bool = false) {
    indexKeys.removeAll(keepCapacity: keepCapacity)
    storage.removeAll(keepCapacity: keepCapacity)
  }

  /**
  sort:

  :param: isOrderedBefore (KeyType, KeyType) -> Bool
  */
  public mutating func sort(isOrderedBefore: (KeyType, KeyType) -> Bool) { indexKeys.sort(isOrderedBefore) }

  /**
  reverse

  :returns: OrderedDictionary<KeyType, ValueType>
  */
  public mutating func reverse() -> OrderedDictionary<KeyType, ValueType> {
    var result = self
    result.indexKeys = result.indexKeys.reverse()
    return result
  }

  /**
  filter:

  :param: includeElement (Element) -> Bool

  :returns: OrderedDictionary<KeyType, ValueType>
  */
  public func filter(includeElement: (Element) -> Bool) -> OrderedDictionary<KeyType, ValueType> {
    var result: OrderedDictionary<KeyType, ValueType> = [:]
    for (k, v) in self { if includeElement((k, v)) { result.setValue(v, forKey: k) } }
    return result
  }

}


////////////////////////////////////////////////////////////////////////////////
/// MARK: - Descriptions
////////////////////////////////////////////////////////////////////////////////

public enum ColonFormatOption {
  case Follow (leftPadding: Int, rightPadding: Int)
  case Align (leftPadding: Int, rightPadding: Int)
  var leftPadding: Int {
    switch self {
      case .Follow(let l, _): return l
      case .Align(let l, _): return l
    }
  }
  var rightPadding: Int {
    switch self {
      case .Follow( _, let r): return r
      case .Align(_, let r): return r
    }
  }
}


extension  OrderedDictionary: Printable, DebugPrintable {

  public var description: String { return storage.description }
  public var debugDescription: String { return storage.debugDescription }

  /**
  formattedDescription:colonFormat:

  i.e. with dictionary ["one": 1, "two": 2, "three": 3] and default values will output:
    one    :  1
    two    :  2
    three  :  3

  :param: indent Int = 0
  :param: colonFormat ColonFormatOption? = nil

  :returns: String
  */
  public func formattedDescription(indent:Int = 0, colonFormat:ColonFormatOption? = nil) -> String {
    var descriptionComponents = [String]()
    let keyDescriptions = indexKeys.map { "\($0)" }
    let maxKeyLength = keyDescriptions.reduce(0) { max($0, countElements($1)) }
    let space = Character(" ")
    let indentString = String(count:indent*4, repeatedValue:space)
    for (key, value) in Zip2(keyDescriptions, values) {
      let spacer = String(count:maxKeyLength-countElements(key)+1, repeatedValue:space)
      var keyString = indentString + key
      if let opt = colonFormat {
        switch opt {
        case let .Follow(l, r):
          keyString += String(count:l, repeatedValue:space) + ":" + String(count:r, repeatedValue:space) + spacer
        case let .Align(l, r):
          keyString += spacer + String(count:l, repeatedValue:space) + ":" + String(count:r, repeatedValue:space)
        }
      } else {
        keyString += spacer + " :  "
      }
      var valueString: String
      var valueComponents = split("\(value)") { $0 == "\n" }
      if valueComponents.count > 0 {
        valueString = valueComponents.removeAtIndex(0)
        if valueComponents.count > 0 {
          let subIndentString = "\n\(indentString)" + String(count:maxKeyLength+3, repeatedValue:Character(" "))
          valueString += subIndentString + join(subIndentString, valueComponents)
        }
      } else { valueString = "nil" }
      descriptionComponents += ["\(keyString)\(valueString)"]
    }
    return join("\n", descriptionComponents)
  }

}


////////////////////////////////////////////////////////////////////////////////
/// MARK: - DictionaryLiteralConvertible
////////////////////////////////////////////////////////////////////////////////


extension  OrderedDictionary: DictionaryLiteralConvertible {

  /**
  init:Value)...:

  :param: elements (Key
  :param: Value)...
  */
  public init(dictionaryLiteral elements: (Key, Value)...) {
    var orderedDict = OrderedDictionary(minimumCapacity: elements.count)
    for (key, value) in elements {
      orderedDict.indexKeys.append(key)
      orderedDict.storage[key] = value
    }
    self = orderedDict
  }

}


////////////////////////////////////////////////////////////////////////////////
/// MARK: - Generator
////////////////////////////////////////////////////////////////////////////////


extension  OrderedDictionary: SequenceType  {


  /**
  generate

  :returns: OrderedDictionaryGenerator<Key, Value>
  */
  public func generate() -> OrderedDictionaryGenerator<Key, Value> {
    return OrderedDictionaryGenerator(value: self)
  }

}

public struct OrderedDictionaryGenerator<Key : Hashable, Value> : GeneratorType {

  let keys: [Key]
  let values: [Value]
  var keyIndex = 0

  /**
  initWithValue:Value>:

  :param: value OrderedDictionary<Key
  :param: Value>
  */
  init(value:OrderedDictionary<Key,Value>) { keys = value.keys; values = value.values }

  /**
  next

  :returns: (Key, Value)?
  */
  public mutating func next() -> (Key, Value)? {
    if keyIndex < keys.count {
      let keyValue = (keys[keyIndex], values[keyIndex])
      keyIndex++
      return keyValue
    } else { return nil }
  }

}

////////////////////////////////////////////////////////////////////////////////
/// MARK: - Operations
////////////////////////////////////////////////////////////////////////////////

/**
Function for creating an `OrderedDictionary` by appending rhs to lhs

:param: lhs OrderedDictionary<K,V>
:param: rhs OrderedDictionary<K,V>

:returns: OrderedDictionary<K,V>
*/
public func +<K,V>(lhs: OrderedDictionary<K,V>, rhs: OrderedDictionary<K,V>) -> OrderedDictionary<K,V> {
  let keys: [K] = lhs.keys + rhs.keys
  let values: [V] = lhs.values + rhs.values
  return OrderedDictionary<K,V>(keys: keys, values: values)
}
