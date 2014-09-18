//
//  OrderedDictionary.swift
//  HomeRemote
//
//  Created by Jason Cardwell on 8/7/14.
//  Copyright (c) 2014 Moondeer Studios. All rights reserved.
//

import Foundation

struct OrderedDictionary<Key : Hashable, Value> : CollectionType {
  typealias KeyType = Key
  typealias ValueType = Value
  typealias Element = (KeyType, ValueType)
  typealias Index = DictionaryIndex<KeyType, ValueType>

  private var storage: [KeyType:ValueType]
  private var indexKeys: [KeyType]
  private var printableKeys = false

  var userInfo: [String:AnyObject]?
  var count: Int { return indexKeys.count }
  var isEmpty: Bool { return indexKeys.isEmpty }
  var keys: [KeyType] { return indexKeys }
  var values: [ValueType] { return indexKeys.map { self.storage[$0]! } }


  ////////////////////////////////////////////////////////////////////////////////
  /// MARK: - Initializers
  ////////////////////////////////////////////////////////////////////////////////


  init(minimumCapacity: Int = 4) {
    storage = [KeyType:ValueType](minimumCapacity: minimumCapacity)
    indexKeys = [KeyType]()
    indexKeys.reserveCapacity(minimumCapacity)
  }

  init<K,V where K:Printable>(minimumCapacity: Int = 4) {
    storage = [KeyType:ValueType](minimumCapacity: minimumCapacity)
    indexKeys = [KeyType]()
    indexKeys.reserveCapacity(minimumCapacity)
    printableKeys = true
  }

  init(_ dict: NSDictionary) {
    self.init(dict as [NSObject:AnyObject])
  }

  init(_ dict:[KeyType:ValueType]) {
    storage = dict
    indexKeys = Array(dict.keys)
    printableKeys = true
  }

  init(keys:[KeyType], values:[ValueType]) {
    self.init(minimumCapacity: keys.count)
    if keys.count == values.count {
      indexKeys += keys
      for i in 0..<keys.count { let k = keys[i]; let v = values[i]; storage[k] = v }
    }
  }


  ////////////////////////////////////////////////////////////////////////////////
  /// MARK: - Indexes
  ////////////////////////////////////////////////////////////////////////////////


  var startIndex: DictionaryIndex<KeyType, ValueType> { return storage.indexForKey(indexKeys[0])! }
  var endIndex: DictionaryIndex<KeyType, ValueType> { return storage.indexForKey(indexKeys.last!)! }
  func indexForKey(key: KeyType) -> DictionaryIndex<KeyType, ValueType>? { return storage.indexForKey(key) }
  subscript (key: KeyType) -> ValueType? { return storage[key] }
  subscript (i: DictionaryIndex<KeyType, ValueType>) -> (KeyType, ValueType) { return storage[i] }


  ////////////////////////////////////////////////////////////////////////////////
  /// MARK: - Updating and removing values
  ////////////////////////////////////////////////////////////////////////////////

  mutating func setValue(value: ValueType, forKey key: KeyType) {
    if indexKeys ∌ key { indexKeys.append(key) }
    storage[key] = value
  }

  mutating func updateValue(value: ValueType, forKey key: KeyType) -> ValueType? {
    let currentValue: ValueType? = indexKeys ∋ key ? storage[key] : nil
    if indexKeys ∌ key { indexKeys.append(key) }
    storage[key] = value
    return currentValue
  }

  mutating func removeAtIndex(index: DictionaryIndex<KeyType, ValueType>) {
    let (k, _) = self[index]
    indexKeys.removeAtIndex(find(indexKeys, k)!)
    storage.removeAtIndex(index)
  }

  mutating func removeValueForKey(key: KeyType) -> ValueType? {
    if let idx = find(indexKeys, key) {
      indexKeys.removeAtIndex(idx)
      return storage.removeValueForKey(key)
    } else {
      return nil
    }
  }

  mutating func removeAll(keepCapacity: Bool = false) {
    indexKeys.removeAll(keepCapacity: keepCapacity)
    storage.removeAll(keepCapacity: keepCapacity)
  }


  func filter(includeElement: (Element) -> Bool) -> OrderedDictionary<KeyType, ValueType> {
    var result: OrderedDictionary<KeyType, ValueType> = [:]
    for (k, v) in self { if includeElement((k, v)) { result.setValue(v, forKey: k) } }
    return result
  }

}


////////////////////////////////////////////////////////////////////////////////
/// MARK: - Descriptions
////////////////////////////////////////////////////////////////////////////////

enum ColonFormatOption {
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

  var description: String { return storage.description }
  var debugDescription: String { return storage.debugDescription }

  //  i.e. with dictionary ["one": 1, "two": 2, "three": 3] and default values will output:
  //  one    :  1
  //  two    :  2
  //  three  :  3
  func formattedDescription(indent:Int = 0, colonFormat:ColonFormatOption? = nil) -> String {
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
  static func convertFromDictionaryLiteral(elements: (KeyType, ValueType)...) -> OrderedDictionary {
    var orderedDict = OrderedDictionary(minimumCapacity: elements.count)
    for (key, value) in elements {
      orderedDict.indexKeys.append(key)
      orderedDict.storage[key] = value
    }
    return orderedDict
  }
}


////////////////////////////////////////////////////////////////////////////////
/// MARK: - Generator
////////////////////////////////////////////////////////////////////////////////


extension  OrderedDictionary: SequenceType  {


  func generate() -> OrderedDictionaryGenerator<Key, Value> {
    return OrderedDictionaryGenerator(value: self)
  }

}

struct OrderedDictionaryGenerator<Key : Hashable, Value> : GeneratorType {

  let keys: [Key]
  let values: [Value]
  var keyIndex = 0

  init(value:OrderedDictionary<Key,Value>) { keys = value.keys; values = value.values }

  mutating func next() -> (Key, Value)? {
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

func +<K,V>(lhs: OrderedDictionary<K,V>, rhs: OrderedDictionary<K,V>) -> OrderedDictionary<K,V> {
  let keys: [K] = lhs.keys + rhs.keys
  let values: [V] = lhs.values + rhs.values
  return OrderedDictionary<K,V>(keys: keys, values: values)
}
