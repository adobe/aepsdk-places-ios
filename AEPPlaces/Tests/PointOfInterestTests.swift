/*
 Copyright 2021 Adobe. All rights reserved.
 This file is licensed to you under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License. You may obtain a copy
 of the License at http://www.apache.org/licenses/LICENSE-2.0
 
 Unless required by applicable law or agreed to in writing, software distributed under
 the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR REPRESENTATIONS
 OF ANY KIND, either express or implied. See the License for the specific language
 governing permissions and limitations under the License.
 */

import XCTest
@testable import AEPPlaces

class PointOfInterestTests: XCTestCase {
    
    static let JSON_STRING = """
    {
        "regionid": "1234",
        "regionname": "myplace",
        "latitude": 12.34,
        "longitude": 23.45,
        "radius": 500,
        "weight": 25,
        "libraryid": "mylib",
        "useriswithin": false,
        "regionmetadata": {
            "stringKey": "value1",
            "intKey": 9,
            "doubleKey": 55.2,
            "boolKey": true,
            "nullKey": null
        }
    }
    """
    
    static let JSON_STRING_SMALL_RADIUS = """
    {
        "regionid": "1234",
        "regionname": "myplace",
        "latitude": 12.34,
        "longitude": 23.45,
        "radius": 100,
        "weight": 25,
        "libraryid": "mylib",
        "useriswithin": false,
        "regionmetadata": {
            "key1": "value1"
        }
    }
    """
    
    static let JSON_STRING_WEIGHT_ONE = """
    {
        "regionid": "1234",
        "regionname": "myplace",
        "latitude": 12.34,
        "longitude": 23.45,
        "radius": 500,
        "weight": 1,
        "libraryid": "mylib",
        "useriswithin": false,
        "regionmetadata": {
            "key1": "value1"
        }
    }
    """
    
    static let EDGE_RESPONSE_MAP: [String: Any] = [
        "p": [
            "1234",
            "myplace",
            "12.34",
            "23.45",
            500,
            "mylib",
            25
        ],
        "x": [
            "key1": "value1"
        ]
    ]
    
    static let EDGE_RESPONSE_MAP_BAD_POI_DATA: [String: Any] = [
        "p": [
            1234,
            3,
            12.34,
            23.45,
            "500",
            424,
            "25"
        ],
        "x": "nope"
    ]
    
    // MARK: - Tests
        
    func testConstructorFromJsonStringHappy() throws {
        // setup
        let poi = try PointOfInterest(jsonString: PointOfInterestTests.JSON_STRING)
        
        // verify
        XCTAssertNotNil(poi)
        XCTAssertEqual("1234", poi.identifier)
        XCTAssertEqual("myplace", poi.name)
        XCTAssertEqual(12.34, poi.latitude)
        XCTAssertEqual(23.45, poi.longitude)
        XCTAssertEqual(500, poi.radius)
        XCTAssertEqual(false, poi.userIsWithin)
        XCTAssertEqual(5, poi.metaData.count)
        XCTAssertEqual("value1", poi.metaData["stringKey"])
        XCTAssertEqual("9", poi.metaData["intKey"])
        XCTAssertEqual("55.2", poi.metaData["doubleKey"])
        XCTAssertEqual("1", poi.metaData["boolKey"])
        XCTAssertEqual("<null>", poi.metaData["nullKey"])
    }
    
    func testConstructorFromJsonStringEmptyJson() throws {
        // setup
        let poi = try PointOfInterest(jsonString: "{}")
        
        // verify
        XCTAssertNotNil(poi)
        XCTAssertEqual("", poi.identifier)
        XCTAssertEqual("", poi.name)
        XCTAssertEqual(PlacesConstants.DefaultValues.INVALID_LAT_LON, poi.latitude)
        XCTAssertEqual(PlacesConstants.DefaultValues.INVALID_LAT_LON, poi.longitude)
        XCTAssertEqual(0, poi.radius)
        XCTAssertEqual(0, poi.weight)
        XCTAssertEqual("", poi.libraryId)
        XCTAssertEqual(false, poi.userIsWithin)
        XCTAssertEqual(0, poi.metaData.count)
    }
    
    func testConstructorFromJsonStringBadJson() throws {
        // setup
        XCTAssertThrowsError(try PointOfInterest(jsonString: "oh no"))
    }
    
    func testConstructorFromJsonObjectHappy() throws {
        // setup
        let poi = try PointOfInterest(jsonObject: PointOfInterestTests.EDGE_RESPONSE_MAP)
        
        // verify
        XCTAssertNotNil(poi)
        XCTAssertEqual("1234", poi.identifier)
        XCTAssertEqual("myplace", poi.name)
        XCTAssertEqual(12.34, poi.latitude)
        XCTAssertEqual(23.45, poi.longitude)
        XCTAssertEqual(500, poi.radius)
        XCTAssertEqual(false, poi.userIsWithin)
        XCTAssertEqual(1, poi.metaData.count)
        XCTAssertEqual("value1", poi.metaData["key1"] as? String)
    }
    
    func testConstructorFromJsonObjectHappyUserWithin() throws {
        // setup
        let poi = try PointOfInterest(jsonObject: PointOfInterestTests.EDGE_RESPONSE_MAP, userIsWithin: true)
        
        // verify
        XCTAssertNotNil(poi)
        XCTAssertEqual("1234", poi.identifier)
        XCTAssertEqual("myplace", poi.name)
        XCTAssertEqual(12.34, poi.latitude)
        XCTAssertEqual(23.45, poi.longitude)
        XCTAssertEqual(500, poi.radius)
        XCTAssertEqual(true, poi.userIsWithin)
        XCTAssertEqual(1, poi.metaData.count)
        XCTAssertEqual("value1", poi.metaData["key1"] as? String)
    }
    
    func testConstructorFromJsonObjectIncorrectJsonArrayData() throws {
        // setup
        let poi = try PointOfInterest(jsonObject: PointOfInterestTests.EDGE_RESPONSE_MAP_BAD_POI_DATA)
        
        // verify
        XCTAssertNotNil(poi)
        XCTAssertEqual("", poi.identifier)
        XCTAssertEqual("", poi.name)
        XCTAssertEqual(PlacesConstants.DefaultValues.INVALID_LAT_LON, poi.latitude)
        XCTAssertEqual(PlacesConstants.DefaultValues.INVALID_LAT_LON, poi.longitude)
        XCTAssertEqual(0, poi.radius)
        XCTAssertEqual(0, poi.weight)
        XCTAssertEqual("", poi.libraryId)
        XCTAssertEqual(false, poi.userIsWithin)
        XCTAssertEqual(0, poi.metaData.count)
    }
    
    func testConstructorFromJsonObjectNoPoi() throws {
        // setup
        let invalidEdgeResponse: [String: Any] = [
            "x": [
                "key1": "value1"
            ]
        ]
        
        // verify
        XCTAssertThrowsError(try PointOfInterest(jsonObject: invalidEdgeResponse))
    }
    
    func testConstructorFromJsonObjectIncorrectPoiArrayCount() throws {
        // setup
        let invalidEdgeResponse: [String: Any] = [
            "p": [
                "1234",
                "myplace",
                12.34,
                23.45,
                500,
                "mylib",
                // 25   << missing value
            ],
            "x": [
                "key1": "value1"
            ]
        ]
        
        // verify
        XCTAssertThrowsError(try PointOfInterest(jsonObject: invalidEdgeResponse))
    }
    
    func testToJsonStringHappy() throws {
        // setup
        let poi = try PointOfInterest(jsonString: PointOfInterestTests.JSON_STRING)
        
        // test
        let resultString = poi.toJsonString()
        
        // verify
        // convert both strings to objects for easier comparison
        let expected = try JSONSerialization.jsonObject(with: PointOfInterestTests.JSON_STRING.data(using: .utf8) ?? Data(),
                                                        options: .mutableContainers) as? [String: Any]
        let result = try JSONSerialization.jsonObject(with: resultString.data(using: .utf8) ?? Data(),
                                                      options: .mutableContainers) as? [String: Any]
        XCTAssertEqual(expected?["regionid"] as? String, result?["regionid"] as? String)
        XCTAssertEqual(expected?["regionname"] as? String, result?["regionname"] as? String)
        XCTAssertEqual(expected?["latitude"] as? Double, result?["latitude"] as? Double)
        XCTAssertEqual(expected?["longitude"] as? Double, result?["longitude"] as? Double)
        XCTAssertEqual(expected?["radius"] as? Int, result?["radius"] as? Int)
        XCTAssertEqual(expected?["weight"] as? Int, result?["weight"] as? Int)
        XCTAssertEqual(expected?["libraryid"] as? String, result?["libraryid"] as? String)
        XCTAssertEqual(expected?["useriswithin"] as? Bool, result?["useriswithin"] as? Bool)
        let eMeta = expected?["regionmetadata"] as? [String: Any]
        let rMeta = result?["regionmetadata"] as? [String: Any]
        XCTAssertEqual(eMeta?["key1"] as? String, rMeta?["key1"] as? String)
    }
    
    func testEqualsSameIdentifier() throws {
        // setup
        let poi1 = try PointOfInterest(jsonString: PointOfInterestTests.JSON_STRING)
        let poi2 = try PointOfInterest(jsonObject: PointOfInterestTests.EDGE_RESPONSE_MAP)
        
        // verify
        XCTAssertTrue(poi1 == poi2)
        XCTAssertTrue(poi2 == poi1)
    }
    
    func testEqualsDifferentIdentifiers() throws {
        // setup
        let poi1 = try PointOfInterest(jsonString: PointOfInterestTests.JSON_STRING)
        poi1.identifier = "something else"
        let poi2 = try PointOfInterest(jsonObject: PointOfInterestTests.EDGE_RESPONSE_MAP)
        
        // verify
        XCTAssertFalse(poi1 == poi2)
        XCTAssertFalse(poi2 == poi1)
    }
    
    func testHasPriorityOverLHSWeightPriority() throws {
        // setup
        let poi1 = try PointOfInterest(jsonString: PointOfInterestTests.JSON_STRING_WEIGHT_ONE)
        let poi2 = try PointOfInterest(jsonString: PointOfInterestTests.JSON_STRING)
        
        // verify
        XCTAssertTrue(poi1.hasPriorityOver(poi2))
        XCTAssertFalse(poi2.hasPriorityOver(poi1))
    }
    
    func testHasPriorityOverRHSWeightPriority() throws {
        // setup
        let poi1 = try PointOfInterest(jsonString: PointOfInterestTests.JSON_STRING)
        let poi2 = try PointOfInterest(jsonString: PointOfInterestTests.JSON_STRING_WEIGHT_ONE)
        
        // verify
        XCTAssertFalse(poi1.hasPriorityOver(poi2))
        XCTAssertTrue(poi2.hasPriorityOver(poi1))
    }
    
    func testHasPriorityOverSameWeightLHSSmallerRadius() throws {
        // setup
        let poi1 = try PointOfInterest(jsonString: PointOfInterestTests.JSON_STRING_SMALL_RADIUS)
        let poi2 = try PointOfInterest(jsonString: PointOfInterestTests.JSON_STRING)
        
        // verify
        XCTAssertTrue(poi1.hasPriorityOver(poi2))
        XCTAssertFalse(poi2.hasPriorityOver(poi1))
    }
    
    func testHasPriorityOverSameWeightRHSSmallerRadius() throws {
        // setup
        let poi1 = try PointOfInterest(jsonString: PointOfInterestTests.JSON_STRING)
        let poi2 = try PointOfInterest(jsonString: PointOfInterestTests.JSON_STRING_SMALL_RADIUS)
        
        // verify
        XCTAssertFalse(poi1.hasPriorityOver(poi2))
        XCTAssertTrue(poi2.hasPriorityOver(poi1))
    }
    
    func testHasPriorityOverSameWeightSameRadius() throws {
        // setup
        let poi1 = try PointOfInterest(jsonString: PointOfInterestTests.JSON_STRING)
        let poi2 = try PointOfInterest(jsonString: PointOfInterestTests.JSON_STRING)
        
        // verify
        // both are true - in the case that both the caller and the passed in values share weight and radius in common,
        // the caller is given priority
        XCTAssertTrue(poi1.hasPriorityOver(poi2))
        XCTAssertTrue(poi2.hasPriorityOver(poi1))
    }
}
