//
//  DataModelTests.swift
//  DataModelTests
//
//  Created by Jason Cardwell on 4/5/15.
//  Copyright (c) 2015 Moondeer Studios. All rights reserved.
//

import UIKit
import XCTest
import CoreData
import DataModel
import MoonKit

class DataModelTests: XCTestCase {

  let context = DataManager.rootContext

  override class func initialize() {
    super.initialize()
    if self === DataModelTests.self {
      MSLog.addTaggingASLLogger()
      MSLog.addTaggingTTYLogger()
    }
  }

  static let testJSON: [String:JSONValue] = {
    var filePaths: [String:JSONValue] = [:]
    if let bundlePath = NSUserDefaults.standardUserDefaults().stringForKey("XCTestedBundlePath"),
      let bundle = NSBundle(path: bundlePath)
    {
      for s in ["Activity", "ActivityController", "ComponentDevice", "Image", "ImageCategory",
                "IRCode", "IRCodeSet", "ISYDevice", "ISYDeviceGroup", "ISYDeviceNode",
                "ITachDevice", "Manufacturer", "Preset", "PresetCategory", "TitleAttributes",
                "Remote", "BuutonGroup", "Button"]
      {
        var error: NSError?
        if let filePath = bundle.pathForResource(s, ofType: "json"),
        json = JSONSerialization.objectByParsingFile(filePath, options: .InflateKeypaths, error: &error)
        where !MSHandleError(error)
        {
          filePaths[s] = json
        }
      }
    }
    return filePaths
    }()

  func assertJSONEquality(data: ObjectJSONValue,
                forObject object: JSONValueConvertible?,
            excludingKeys excluded: [String] = [])
  {
    let expectedData = data.value.filter({(k, _) in excluded ∌ k})
    if let actualData = ObjectJSONValue(object?.jsonValue)?.value.filter({(k, _) in excluded ∌ k}) {
      for (key, json) in expectedData {
        XCTAssert(json == actualData[key], "'\(toString(actualData[key]?.prettyStringValue))' != '\(json.prettyStringValue)' for key '\(key)'")
      }
    } else { XCTFail("failed to get json value of created object") }
  }

  func testLoadManufacturersFromFile() {
    let expectation = expectationWithDescription("load manufacturers")
    DataManager.loadDataFromFile("Manufacturer_Test",
                            type: Manufacturer.self,
                         context: context,
                      completion: {(success: Bool, error: NSError?) -> Void in
                        XCTAssertTrue(success, "loading data from file triggered an error")
                        DataManager.saveRootContext(completion: { (success: Bool, error: NSError?) -> Void in
                          XCTAssertTrue(success, "saving context triggered an error")
                          expectation.fulfill()
                        })
                      })
    waitForExpectationsWithTimeout(10, handler: {(error: NSError?) -> Void in _ = MSHandleError(error)})
    let manufacturers = Manufacturer.objectsInContext(context) as! [Manufacturer]
    XCTAssertTrue(manufacturers.count > 0, "where are the manufacturer objects?")
    XCTAssertEqual(manufacturers[0].name, "Dish", "unexpected name")
    let codeSets = manufacturers[0].codeSets
    XCTAssertEqual(codeSets.count, 1, "where is the code set?")
    let codeSet = IRCodeSet.objectMatchingPredicate(∀"manufacturer.name == 'Dish'", context: context)
    XCTAssertNotNil(codeSet, "where is the code set?")
    if codeSet != nil {
      XCTAssertEqual(codeSet!.codes.count, 47, "unexpected count for code set's codes array")
    }
  }

  func testDictionaryStorage() {
    let storage = DictionaryStorage(context: context)
    XCTAssert(storage.entityName == "DictionaryStorage", "failed to create new instance of `Dictionary Storage`")
    let key1 = "key1", key2 = "key2", key3 = "key3"
    let value1 = "value1", value2 = 2, value3 = ["value3"]
    storage[key1] = value1; storage[key2] = value2; storage[key3] = value3
    let stored1 = storage[key1] as? String, stored2 = storage[key2] as? Int, stored3 = storage[key3] as? [String]
    XCTAssertNotNil(stored1); XCTAssertNotNil(stored2); XCTAssertNotNil(stored3)
    if let s1 = stored1, s2 = stored2, s3 = stored3 {
      XCTAssert(s1 == value1); XCTAssert(s2 == value2); XCTAssert(s3 == value3)
    }
  }

  func testJSONStorage() {
    let storage = JSONStorage(context: context)
    XCTAssert(storage.entityName == "JSONStorage", "failed to create new instance of `JSON Storage`")
    let key1 = "key1", key2 = "key2", key3 = "key3"
    let value1 = "value1", value2 = 2, value3 = ["value3"]
    storage[key1] = value1.jsonValue; storage[key2] = value2.jsonValue; storage[key3] = JSONValue(value3)
    let stored1 = String(storage[key1]), stored2 = Int(storage[key2]), stored3 = compressedMap(ArrayJSONValue(storage[key3]), {String($0)})
    XCTAssertNotNil(stored1); XCTAssertNotNil(stored2); XCTAssertNotNil(stored3)
    if let s1 = stored1, s2 = stored2, s3 = stored3 {
      XCTAssert(s1 == value1); XCTAssert(s2 == value2); XCTAssert(s3 == value3)
    }
  }

  func testActivity() {
    if let data = ObjectJSONValue(self.dynamicType.testJSON["Activity"]) {
      let activity = Activity(data: data, context: context)
      XCTAssert(activity != nil)
      assertJSONEquality(data, forObject: activity, excludingKeys: ["remote", "launch-macro", "halt-macro"])
      XCTAssertNotNil(activity?.launchMacro)
      XCTAssertNotNil(activity?.haltMacro)
    } else { XCTFail("could not retrieve test json for `Activity`") }
  }

//  func testActivityController() {
//    if let data = ObjectJSONValue(self.dynamicType.testJSON["ActivityController"]) {
//      let activityController = ActivityController(data: data, context: context)
//      XCTAssert(activityController != nil)
//      XCTFail("need to fix issue with missing values crashing program")
////      assertJSONEquality(data, forObject: activityController, excludingKeys: [])
//      // MSLogDebug("activityController = \(toString(activityController))")
//    } else { XCTFail("could not retrieve test json for `ActivityController`") }
//  }

  func testComponentDevice() {
    if let data = ObjectJSONValue(self.dynamicType.testJSON["ComponentDevice"]) {
      let componentDevice = ComponentDevice(data: data, context: context)
      XCTAssert(componentDevice != nil)
      assertJSONEquality(data, forObject: componentDevice, excludingKeys: ["code-set", "manufacturer"])
    } else { XCTFail("could not retrieve test json for `ComponentDevice`") }
  }

  func testIRCode() {
    if let data = ObjectJSONValue(self.dynamicType.testJSON["IRCode"]) {
      let irCode = IRCode(data: data, context: context)
      XCTAssert(irCode != nil)
      assertJSONEquality(data, forObject: irCode)
    } else { XCTFail("could not retrieve test json for `IRCode`") }
  }

  func testIRCodeSet() {
    if let data = ObjectJSONValue(self.dynamicType.testJSON["IRCodeSet"]) {
      let irCodeSet = IRCodeSet(data: data, context: context)
      XCTAssert(irCodeSet != nil)
      assertJSONEquality(data, forObject: irCodeSet, excludingKeys: ["codes"])
    } else { XCTFail("could not retrieve test json for `IRCodeSet`") }
  }

  func testISYDevice() {
    if let data = ObjectJSONValue(self.dynamicType.testJSON["ISYDevice"]) {
      let isyDevice = ISYDevice(data: data, context: context)
      XCTAssert(isyDevice != nil)
      assertJSONEquality(data, forObject: isyDevice, excludingKeys: ["nodes", "groups"])
    } else { XCTFail("could not retrieve test json for `ISYDevice`") }
  }

  func testISYDeviceGroup() {
    if let data = ObjectJSONValue(self.dynamicType.testJSON["ISYDeviceGroup"]) {
      let isyDeviceGroup = ISYDeviceGroup(data: data, context: context)
      XCTAssert(isyDeviceGroup != nil)
      assertJSONEquality(data, forObject: isyDeviceGroup, excludingKeys: ["members", "device"])
    } else { XCTFail("could not retrieve test json for `ISYDeviceGroup`") }
  }

  func testISYDeviceNode() {
    if let data = ObjectJSONValue(self.dynamicType.testJSON["ISYDeviceNode"]) {
      let isyDeviceNode = ISYDeviceNode(data: data, context: context)
      XCTAssert(isyDeviceNode != nil)
      assertJSONEquality(data, forObject: isyDeviceNode, excludingKeys: ["groups", "device"])
    } else { XCTFail("could not retrieve test json for `ISYDeviceNode`") }
  }

  func testITachDevice() {
    if let data = ObjectJSONValue(self.dynamicType.testJSON["ITachDevice"]) {
      let iTachDevice = ITachDevice(data: data, context: context)
      XCTAssert(iTachDevice != nil)
      assertJSONEquality(data, forObject: iTachDevice)
    } else { XCTFail("could not retrieve test json for `ITachDevice`") }
  }

  func testImage() {
    if let data = ObjectJSONValue(self.dynamicType.testJSON["Image"]) {
      let image = Image(data: data, context: context)
      XCTAssert(image != nil)
      assertJSONEquality(data, forObject: image, excludingKeys: [])
    } else { XCTFail("could not retrieve test json for `Image`") }
  }

  func testImageCategory() {
    if let data = ObjectJSONValue(self.dynamicType.testJSON["ImageCategory"]) {
      let imageCategory = ImageCategory(data: data, context: context)
      XCTAssert(imageCategory != nil)
      assertJSONEquality(data, forObject: imageCategory, excludingKeys: ["images"])
      if let expectedImageCount = data["images"]?.arrayValue?.count,
        images = imageCategory?.images
      {
        XCTAssertEqual(expectedImageCount, images.count)
      }
    } else { XCTFail("could not retrieve test json for `ImageCategory`") }
  }

  func testManufacturer() {
    if let data = ObjectJSONValue(self.dynamicType.testJSON["Manufacturer"]) {
      let manufacturer = Manufacturer(data: data, context: context)
      XCTAssert(manufacturer != nil)
      assertJSONEquality(data, forObject: manufacturer, excludingKeys: ["code-sets"])
      if let expectedCodeSetCount = data["code-sets"]?.arrayValue?.count,
        codeSets = manufacturer?.codeSets
      {
        XCTAssertEqual(expectedCodeSetCount, codeSets.count)
      }
    } else { XCTFail("could not retrieve test json for `Manufacturer`") }
  }

  func testModelIndex() {
    let uuid = "4E9FE3CD-A64C-4D6D-8E3D-F7F5B7D7EB92"
    let uuidIndex = UUIDIndex(uuid)
    XCTAssert(uuidIndex != nil)
    XCTAssert(uuidIndex?.rawValue == uuid)

    let path = "I/Am/a%20Path"
    let pathIndex = PathIndex(path)
    XCTAssert(pathIndex != nil)
    XCTAssert(pathIndex?.rawValue == path)
    XCTAssert(pathIndex?.first == "I")
    XCTAssert(pathIndex?.last == "a%20Path")
    XCTAssert(pathIndex?.count == 3)
  }

  func testPreset() {
    if let data = ObjectJSONValue(self.dynamicType.testJSON["Preset"]) {
      let preset = Preset(data: data, context: context)
      XCTAssert(preset != nil)
      assertJSONEquality(data, forObject: preset, excludingKeys: ["subelements"])
      if let expectedSubelementsCount = data["subelements"]?.arrayValue?.count,
        subelements = preset?.subelements
      {
        XCTAssertEqual(expectedSubelementsCount, subelements.count)
      }
    } else { XCTFail("could not retrieve test json for `Preset`") }
  }

  func testPresetCategory() {
    if let data = ObjectJSONValue(self.dynamicType.testJSON["PresetCategory"]) {
      let presetCategory = PresetCategory(data: data, context: context)
      XCTAssert(presetCategory != nil)
      assertJSONEquality(data, forObject: presetCategory, excludingKeys: ["presets"])
      if let expectedPresetsCount = data["presets"]?.arrayValue?.count,
        presets = presetCategory?.presets
      {
        XCTAssertEqual(expectedPresetsCount, presets.count)
      }
    } else { XCTFail("could not retrieve test json for `PresetCategory`") }
  }

  func testTitleAttributes() {
    if let data = self.dynamicType.testJSON["TitleAttributes"] {
      let titleAttributes = TitleAttributes(data)
      XCTAssert(titleAttributes != nil)
      assertJSONEquality(ObjectJSONValue(data)!, forObject: titleAttributes)
    } else { XCTFail("could not retrieve test json for `TitleAttributes`") }
  }

  func testButton() {
    if let data = ObjectJSONValue(self.dynamicType.testJSON["Button"]) {
      if let button = Button(data: data, context: context) {
        assertJSONEquality(data, forObject: button, excludingKeys: ["commands", "titles", "background-colors"])
      } else { XCTFail("failed to create button") }
    } else { XCTFail("could not retrieve test json for `Button`") }
  }

}
