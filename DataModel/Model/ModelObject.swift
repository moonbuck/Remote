//
//  ModelObject.swift
//  Remote
//
//  Created by Jason Cardwell on 9/30/14.
//  Copyright (c) 2014 Moondeer Studios. All rights reserved.
//

import Foundation
import CoreData
import MoonKit
import ObjectiveC

@objc(ModelObject)
public class ModelObject: NSManagedObject, Model, JSONValueConvertible {


  /// MARK: - Initializers
  ////////////////////////////////////////////////////////////////////////////////

  /**
  initWithEntity:insertIntoManagedObjectContext:

  - parameter entity: NSEntityDescription
  - parameter context: NSManagedObjectContext?
  */
  override public init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
    super.init(entity: entity, insertIntoManagedObjectContext: context)
    setPrimitiveValue(MSNonce(), forKey: "uuid")
 }

  /**
  initWithContext:

  - parameter context: NSManagedObjectContext
  */
  public init(context: NSManagedObjectContext?) {
    super.init(entity: self.dynamicType.entityDescription, insertIntoManagedObjectContext: context)
    setPrimitiveValue(MSNonce(), forKey: "uuid")
 }

  /**
  initWithUuid:context:

  - parameter uuid: String
  - parameter context: NSManagedObjectContext
  */
  public init?(uuid: String, context: NSManagedObjectContext) {
    super.init(entity: self.dynamicType.entityDescription, insertIntoManagedObjectContext: nil)
    if self.dynamicType.objectWithUUID(uuid, context: context) == nil && self.dynamicType.isValidUUID(uuid) {
      context.insertObject(self)
      setPrimitiveValue(uuid, forKey: "uuid")
    } else { return nil }
  }

  /**
  initWithData:context:

  - parameter data: ObjectJSONValue
  - parameter context: NSManagedObjectContext
  */
  required public init?(data: ObjectJSONValue, context: NSManagedObjectContext) {
    if let uuid = String(data["uuid"]) {
      super.init(entity: self.dynamicType.entityDescription, insertIntoManagedObjectContext: nil)
      if self.dynamicType.objectWithUUID(uuid, context: context) == nil && self.dynamicType.isValidUUID(uuid) {
        context.insertObject(self)
        setPrimitiveValue(uuid, forKey: "uuid")
      } else { return nil }
    } else {
      super.init(entity: self.dynamicType.entityDescription, insertIntoManagedObjectContext: context)
      setPrimitiveValue(MSNonce(), forKey: "uuid")
    }
    updateWithData(data)
  }


  // MARK: - Properties


  /**
  The one property all core data entities need to have in the model to be representable as a `ModelObject`. The value
  of an object's `uuid` attribute serves as a unique identifier for the lifetime of the object.
  */
  @NSManaged private(set) public var uuid: String

  public var uuidIndex: UUIDIndex {
    if let uuidIndex = UUIDIndex(rawValue: uuid) { return uuidIndex }
    else { fatalError("unable to generate uuid index for model, is uuid nil?") }
  }

  /** Accessor for the model's `uuid` as a `UUIDIndex` */
  public var index: ModelIndex { return ModelIndex(uuidIndex) }

  /** Entity description retrieved from the managed object model */
  public class var entityDescription: NSEntityDescription {
    let entities = DataManager.managedObjectModel.entities as [NSEntityDescription]
    let name = className().substringForCapture(1, inFirstMatchFor: ~/"^([^_0-9]+)")
    if let entity = findFirst(entities, {$0.managedObjectClassName == name}) { return entity }
    else { fatalError("unable to locate entity for class '\(className())'") }
  }

  /**
  entityName:

  - parameter context: NSManagedObjectContext = DataManager.rootContext

  - returns: String
  */
  public class var entityName: String { return entityDescription.name! }
  public var entityName: String { return self.dynamicType.entityName }

  /// MARK: - Validation
  ////////////////////////////////////////////////////////////////////////////////


  /**
  isValidUUID:

  - parameter uuid: String

  - returns: Bool
  */
  public class func isValidUUID(uuid: String) -> Bool { return uuid ~= "[A-F0-9]{8}-(?:[A-F0-9]{4}-){3}[A-Z0-9]{12}" }


  /// MARK: - Fetching existing objects
  ////////////////////////////////////////////////////////////////////////////////


  /**
  objectWithUUID:context:

  - parameter uuid: String
  - parameter context: NSManagedObjectContext

  - returns: Self?
  */
  public class func objectWithUUID(uuid: String, context: NSManagedObjectContext) -> Self? {
    if isValidUUID(uuid) { return objectWithValue(uuid, forAttribute: "uuid", context: context) } else { return nil }
  }

  /**
  objectWithUUIDIndex:context:

  - parameter uuidIndex: UUIDIndex
  - parameter context: NSManagedObjectContext

  - returns: Self?
  */
  public class func objectWithUUID(uuidIndex: UUIDIndex, context: NSManagedObjectContext) -> Self? {
    return objectWithUUID(uuidIndex.rawValue, context: context)
  }

  /**
  objectWithIndex:context:

  - parameter index: ModelIndex
  - parameter context: NSManagedObjectContext

  - returns: Self?
  */
  public class func objectWithIndex(index: ModelIndex, context: NSManagedObjectContext) -> Self? {
    if let uuidIndex = index.uuidIndex { return objectWithUUID(uuidIndex.rawValue, context: context) }
    else { return nil }
  }

  /**
  Returns the existing object matched by `data` or nil if no match exists

  - parameter data: ObjectJSONValue
  - parameter context: NSManagedObjectContext

  - returns: Self?
  */
  public class func objectWithData(data: ObjectJSONValue, context: NSManagedObjectContext) -> Self? {
    if let uuid = String(data["uuid"]), object = objectWithUUID(uuid, context: context) { return object }
    else if let rawIndex = String(data["index"]) {
      return objectWithIndex(ModelIndex(rawIndex), context: context)
    }
    else { return nil }
  }

  /**
  Returns the first object found with a matching `value` for `attribute` or nil if none exists

  - parameter value: AnyObject
  - parameter attribute: String
  - parameter context: NSManagedObjectContext

  - returns: Self?
  */
  public class func objectWithValue(value: AnyObject,
                       forAttribute attribute: String,
                            context: NSManagedObjectContext) -> Self?
  {
    return objectMatchingPredicate(NSPredicate(format: "%K == %@", argumentArray: [attribute, value]), context: context)
  }

  /**
  objectsWithValue:forAttribute:context:

  - parameter value: AnyObject
  - parameter attribute: String
  - parameter context: NSManagedObjectContext

  - returns: [ModelObject]
  */
  public class func objectsWithValue(value: AnyObject,
                        forAttribute attribute: String,
                             context: NSManagedObjectContext) -> [ModelObject]
  {
    return objectsMatchingPredicate(NSPredicate(format: "%K == %@", argumentArray: [attribute, value]), context: context)
  }

  /**
  objectMatchingPredicate:context:

  - parameter predicate: NSPredicate
  - parameter context: NSManagedObjectContext

  - returns: Self?
  */
//  public class func objectMatchingPredicate(predicate: NSPredicate, context: NSManagedObjectContext) -> Self? {
//    return objectMatchingPredicate(predicate, context: context, type: self)
//  }

  public class func objectMatchingPredicate<T>(predicate: NSPredicate, context: NSManagedObjectContext) -> T? {
    return objectsMatchingPredicate(predicate, fetchLimit: 1, context: context).first as? T
  }

  /**
  objectsMatchingPredicate:fetchLimit:sortBy:ascending:context:error:

  - parameter predicate: NSPredicate
  - parameter fetchLimit: Int = 0
  - parameter sortBy: String? = nil
  - parameter ascending: Bool = true
  - parameter context: NSManagedObjectContext
  - parameter error: NSErrorPointer = nil

  - returns: [ModelObject]
  */
  public class func objectsMatchingPredicate(predicate: NSPredicate,
                                  fetchLimit: Int = 0,
                                      sortBy: String? = nil,
                                   ascending: Bool = true,
                                     context: NSManagedObjectContext,
                                       error: NSErrorPointer = nil) -> [ModelObject]
  {
    let request = NSFetchRequest(entityName: entityName, predicate: predicate)
    request.fetchLimit = fetchLimit
    if let sortBy = sortBy {
      request.sortDescriptors = ",".split(sortBy).map {
        (s:String) -> NSSortDescriptor in return NSSortDescriptor(key: s, ascending: ascending)
      }
    }
    do {
      let results = try context.executeFetchRequest(request)
      return results as! [ModelObject]
    } catch {
      return []
    }
  }

  /**
  objectsInContext:sortBy:ascending:

  - parameter context: NSManagedObjectContext
  - parameter sortBy: String? = nil
  - parameter ascending: Bool = true

  - returns: [ModelObject]
  */
  public class func objectsInContext(context: NSManagedObjectContext,
                       sortBy: String? = nil,
                    ascending: Bool = true) -> [ModelObject]
  {
    return objectsMatchingPredicate(∀"TRUEPREDICATE", sortBy: sortBy, ascending: ascending, context: context)
  }

  /**
  objectsInContext:groupedBy:withPredicate:sortedBy:ascending:

  - parameter context: NSManagedObjectContext
  - parameter groupBy: String? = nil
  - parameter predicate: NSPredicate = (default)
  - parameter sortBy: String
  - parameter ascending: Bool = true

  - returns: NSFetchedResultsController
  */
  public class func objectsInContext(context: NSManagedObjectContext,
                    groupedBy groupBy: String? = nil,
                withPredicate predicate: NSPredicate = ∀"TRUEPREDICATE",
                     sortedBy sortBy: String,
                    ascending: Bool = true) -> NSFetchedResultsController
  {
    let request = NSFetchRequest(entityName: entityName, predicate: predicate)
    if let g = groupBy {request.propertiesToGroupBy = ",".split(g) }
    request.sortDescriptors = ",".split(sortBy).map {
      (s:String) -> NSSortDescriptor in
        return NSSortDescriptor(key: s, ascending: ascending)
      }
    return NSFetchedResultsController(fetchRequest: request,
                                      managedObjectContext: context,
                                      sectionNameKeyPath: nil,
                                      cacheName: nil)
  }

  /// MARK: - Fetching attribute values for existing objects
  ////////////////////////////////////////////////////////////////////////////////


  /**
  allValuesForAttribute:context:

  - parameter attribute: String
  - parameter context: NSManagedObjectContext

  - returns: [AnyObject]
  */
  public class func allValuesForAttribute(attribute: String, context: NSManagedObjectContext) -> [AnyObject] {
    let request = NSFetchRequest(entityName: entityName)
    request.resultType = .DictionaryResultType
    request.returnsDistinctResults = true
    request.propertiesToFetch = [attribute]

    do {
      let results = try context.executeFetchRequest(request)
      return compressedMap(results) {($0 as? [String:AnyObject])?[attribute]}
    } catch {
      MSHandleError(error as NSError)
      return []
    }
  }


  /// MARK: - Importing
  ////////////////////////////////////////////////////////////////////////////////


  /**
  Attempts to fetch an existing object using `data` and if that fails a new object is created

  - parameter data: ObjectJSONValue
  - parameter context: NSManagedObjectContext

  - returns: Self?
  */
  public class func importObjectWithData(data: ObjectJSONValue, context: NSManagedObjectContext) -> Self? {
    if let object = objectWithData(data, context: context) { return object }
    else { return self.init(data: data, context: context) }
  }

  public class func importObjectWithData(data: ObjectJSONValue?, context: NSManagedObjectContext) -> Self? {
    if let d = data { return importObjectWithData(d, context: context) } else { return nil }
  }

  /**
  importObjectsWithData:context:

  - parameter data: ArrayJSONValue
  - parameter context: NSManagedObjectContext

  - returns: [ModelObject]
  */
  public class func importObjectsWithData(data: ArrayJSONValue, context: NSManagedObjectContext) -> [ModelObject] {
    return compressedMap(compressedMap(data, {ObjectJSONValue($0)}), {self.importObjectWithData($0, context: context)})
  }


  /// MARK: - Updating
  ////////////////////////////////////////////////////////////////////////////////


  /**
  updateWithData:

  - parameter data: ObjectJSONValue
  */
  public func updateWithData(data:ObjectJSONValue) {}

  /**
  updateRelationship:withData:

  - parameter relationship: NSRelationshipDescription
  - parameter data: ObjectJSONValue

  - returns: Bool
  */
  private func updateRelationship(relationship: NSRelationshipDescription, withData data: ObjectJSONValue) -> Bool {
    if !relationship.toMany, let moc = managedObjectContext,
      relatedTypeName = relationship.destinationEntity?.managedObjectClassName,
      relatedType = NSClassFromString(relatedTypeName) as? ModelObject.Type
    {
      let relatedObject: ModelObject?
      if let index = String(data["index"]) { relatedObject = relatedType.objectWithIndex(ModelIndex(index), context: moc) }
      else { relatedObject = relatedType.importObjectWithData(data, context: moc) }
      if relatedObject == nil { return false }
      setPrimitiveValue(relatedObject!, forKey: relationship.name)
      if let inverse = relationship.inverseRelationship {
        if inverse.toMany {
          if inverse.ordered {
            let inverseRelatedSet = relatedObject!.mutableOrderedSetValueForKey(inverse.name)
            inverseRelatedSet.addObject(self)
          } else {
            let inverseRelatedSet = relatedObject!.mutableSetValueForKey(inverse.name)
            inverseRelatedSet.addObject(self)
          }
        } else {
          relatedObject!.setPrimitiveValue(self, forKey: inverse.name)
        }
        return true
      }
    }

    return false
  }

  /**
  updateRelationship:withData:

  - parameter relationship: NSRelationshipDescription
  - parameter data: ArrayJSONValue

  - returns: Bool
  */
  private func updateRelationship(relationship: NSRelationshipDescription, withData data: ArrayJSONValue) -> Bool {
    if let moc = managedObjectContext,
      relatedTypeName = relationship.destinationEntity?.managedObjectClassName,
      relatedType = NSClassFromString(relatedTypeName) as? ModelObject.Type where relationship.toMany
    {
      let relatedObjects = relatedType.importObjectsWithData(data, context: moc)
      setPrimitiveValue(relationship.ordered ? NSOrderedSet(array: relatedObjects) : NSSet(array: relatedObjects), forKey: relationship.name)
      if let inverseRelationship = relationship.inverseRelationship {
        if inverseRelationship.toMany {
          if inverseRelationship.ordered {
            apply(relatedObjects, {$0.mutableOrderedSetValueForKey(inverseRelationship.name).addObject(self)})
          } else {
            apply(relatedObjects, {$0.mutableSetValueForKey(inverseRelationship.name).addObject(self)})
          }
        } else {
          apply(relatedObjects, {$0.setPrimitiveValue(self, forKey: inverseRelationship.name)})
        }
        return true
      }
    }

    return false
  }

  /**
  relatedObjectWithData:forKey:lookupKey:

  - parameter data: ObjectJSONValue
  - parameter key: String
  - parameter lookupKey: String? = nil

  - returns: T?
  */
  public func relatedObjectWithData<T:ModelObject>(data: ObjectJSONValue, forAttribute attribute: String, lookupKey: String? = nil) -> T? {
    if let relationshipDescription = entity.relationshipsByName[attribute],
      relatedTypeName = relationshipDescription.destinationEntity?.managedObjectClassName,
      relatedType = NSClassFromString(relatedTypeName) as? ModelObject.Type,
      relatedObjectData = ObjectJSONValue(data[lookupKey ?? attribute]),
      moc = managedObjectContext
    {
      return relatedType.objectWithData(relatedObjectData, context: moc) as? T
    } else { return nil }
  }

  /**
  updateRelationshipFromData:forKey:

  - parameter data: ObjectJSONValue
  - parameter key: String

  - returns: Bool
  */
  public func updateRelationshipFromData(data: ObjectJSONValue, forAttribute attribute: String, lookupKey: String? = nil) -> Bool {

    // Retrieve the relationship description
    if let relationshipDescription = entity.relationshipsByName[attribute] {
      // Obtain relationship data
      let key = lookupKey ?? attribute
      if let relationshipData = ObjectJSONValue(data[key] ?? .Null) where !relationshipDescription.toMany {
        return updateRelationship(relationshipDescription, withData: relationshipData)
      } else if let relationshipData = ArrayJSONValue(data[key] ?? .Null) where relationshipDescription.toMany {
        return updateRelationship(relationshipDescription, withData: relationshipData)
      }
    }

    return false
  }


  /// MARK: - Counting
  ////////////////////////////////////////////////////////////////////////////////

  /**
  countInContext:withValue:forAttribute:

  - parameter context: NSManagedObjectContext
  - parameter value: AnyObject
  - parameter attribute: String

  - returns: Int
  */
  public class func countInContext(context: NSManagedObjectContext,
                         withValue value: AnyObject,
                      forAttribute attribute: String) -> Int
  {
    return countInContext(context, predicate: NSPredicate(format: "%K == %@", argumentArray: [attribute, value]))
  }


  /**
  countInContext:predicate:

  - parameter context: NSManagedObjectContext
  - parameter predicate: NSPredicate

  - returns: Int
  */
  public class func countInContext(context: NSManagedObjectContext, predicate: NSPredicate = ∀"TRUEPREDICATE") -> Int {
    let request = NSFetchRequest(entityName: entityName, predicate: predicate)
    var error: NSError?
    let result = context.countForFetchRequest(request, error: &error)
    MSHandleError(error)
    return result
  }

  /**
  objectExistsInContext:withValue:forAttribute:

  - parameter context: NSManagedObjectContext
  - parameter value: AnyObject
  - parameter attribute: String

  - returns: Bool
  */
  public class func objectExistsInContext(context: NSManagedObjectContext,
                                withValue value: AnyObject,
                             forAttribute attribute: String) -> Bool
  {
    return countInContext(context, withValue: value, forAttribute: attribute) > 0
  }


  /// MARK: - Deleting
  ////////////////////////////////////////////////////////////////////////////////


  /**
  deleteObjectsInContext:

  - parameter context: NSManagedObjectContext
  */
  public class func deleteObjectsInContext(context: NSManagedObjectContext) {
    deleteObjectsMatchingPredicate(∀"TRUEPREDICATE", context: context)
  }

  /**
  deleteObjectsMatchingPredicate:context:

  - parameter predicate: NSPredicate
  - parameter context: NSManagedObjectContext
  */
  public class func deleteObjectsMatchingPredicate(predicate: NSPredicate, context: NSManagedObjectContext) {
    context.deleteObjects(Set(objectsMatchingPredicate(predicate, context: context)))
  }


  /// MARK: - Exporting
  ////////////////////////////////////////////////////////////////////////////////


  /**
  hasDefaultValue:

  - parameter attribute: String

  - returns: Bool
  */
  public func hasDefaultValue(attribute: String) -> Bool {
    if let value: AnyObject = valueForKey(attribute),
      let defaultValue: AnyObject = defaultValueForAttribute(attribute) where value.isEqual(defaultValue) { return true }
    else { return valueForKey(attribute) == nil && defaultValueForAttribute(attribute) == nil }
  }

  /**
  hasNonDefaultValue:

  - parameter attribute: String

  - returns: Bool
  */
  public func hasNonDefaultValue(attribute: String) -> Bool {
    return !hasDefaultValue(attribute)
  }


  /**
  appendValueForKey:forKey:ifNotDefault:toObject:

  - parameter key: String
  - parameter forKey: String? = nil
  - parameter nonDefault: Bool = true
  - parameter object: ObjectJSONValue
  */
  public func appendValueForKey(key: String,
                  forKey: String? = nil,
            ifNotDefault nonDefault: Bool = false,
            inout toObject object: ObjectJSONValue)
  {
    let value: Any?
    if let attributeDescription = entity.attributesByName[key]
      where attributeDescription.attributeType == .BooleanAttributeType
    {
      value = (valueForKey(key) as? NSNumber)?.boolValue
    } else { value = valueForKey(key) }
    appendValue(value,
         forKey: forKey ?? key,
   ifNotDefault: nonDefault,
       toObject: &object)
  }

  /**
  appendValueForKeyPath:forKey:ifNotDefault:toObject:

  - parameter keypath: String
  - parameter key: String
  - parameter object: ObjectJSONValue
  */
  public func appendValueForKeyPath(keypath: String,
                             forKey key: String? = nil,
            ifNotDefault nonDefault: Bool = false,
                 inout toObject object: ObjectJSONValue)
  {
    appendValue(valueForKeyPath(keypath),
         forKey: key ?? keypath,
   ifNotDefault: nonDefault,
       toObject: &object)
  }

  /**
  appendValue:forKey:ifNotDefault:toObject:

  - parameter keypath: String
  - parameter key: String
  - parameter object: ObjectJSONValue
  */
  public func appendValue(value: Any?,
                   forKey key: String,
             ifNotDefault nonDefault: Bool = false,
       inout toObject object: ObjectJSONValue)
  {
    if !(nonDefault && hasDefaultValue(key)) {
      if let convertibleValue = value as? JSONValueConvertible {
        object[key] = convertibleValue.jsonValue
      } else if let convertibleValues = value as? [JSONValueConvertible] {
        object[key] = .Array(convertibleValues.map({$0.jsonValue}))
      } else if let convertibleValues = value as? Set<ModelObject> {
        object[key] = .Array(Array(convertibleValues).map({$0.jsonValue}))
      } else {
        object[key] = JSONValue(value)
      }

    }
  }

  public var jsonValue: JSONValue { return .Object(["uuid": uuid.jsonValue] as OrderedDictionary) }

  override public var description: String {
    return "\(className):\n\t" + "\n\t".join(
      "entity = \(entityName)",
      "index = \(index.rawValue)" + (self is PathIndexedModel ? "\n\tuuid = \(uuid)" : "")
    )
  }
}

/**
`Equatable` support for `ModelObject`

- parameter lhs: ModelObject
- parameter rhs: ModelObject

- returns: Bool
*/
public func ==(lhs: ModelObject, rhs: ModelObject) -> Bool { return lhs.isEqual(rhs) }
