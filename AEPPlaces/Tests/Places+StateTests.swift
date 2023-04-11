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

import CoreLocation
import XCTest
@testable import AEPPlaces

class PlacesPlusStateTests: XCTestCase {
    static let JSON_STRING = """
    {
        "regionid": "1234",
        "regionname": "myplace",
        "latitude": 12.34,
        "longitude": 23.45,
        "radius": 500,
        "weight": 25,
        "libraryid": "mylib",
        "useriswithin": true,
        "regionmetadata": {
            "key1": "value1"
        }
    }
    """

    var places = Places(runtime: TestableExtensionRuntime())!
    var poi: PointOfInterest = try! PointOfInterest(jsonString: JSON_STRING)

    override func setUpWithError() throws {

    }

    override func tearDownWithError() throws {
        clearPlacesDataStore()
    }

    // MARK: - helpers

    func populatePlacesState() {
        places.nearbyPois[poi.identifier] = poi
        places.userWithinPois[poi.identifier] = poi
        places.currentPoi = poi
        places.lastEnteredPoi = poi
        places.lastExitedPoi = poi
        places.lastKnownCoordinate = CLLocationCoordinate2D(latitude: poi.latitude, longitude: poi.longitude)
        places.authStatus = .authorizedAlways
        places.membershipValidUntil = Date().timeIntervalSince1970 + 60
    }

    func populatePlacesDataStore() {
        places.dataStore.set(key: PlacesConstants.UserDefaults.PERSISTED_NEARBY_POIS, value: [poi.identifier: poi.toJsonString()])
        places.dataStore.set(key: PlacesConstants.UserDefaults.PERSISTED_USER_WITHIN_POIS, value: [poi.identifier: poi.toJsonString()])
        places.dataStore.set(key: PlacesConstants.UserDefaults.PERSISTED_CURRENT_POI, value: poi.toJsonString())
        places.dataStore.set(key: PlacesConstants.UserDefaults.PERSISTED_LAST_ENTERED_POI, value: poi.toJsonString())
        places.dataStore.set(key: PlacesConstants.UserDefaults.PERSISTED_LAST_EXITED_POI, value: poi.toJsonString())
        places.dataStore.set(key: PlacesConstants.UserDefaults.PERSISTED_LATITUDE, value: 12.34)
        places.dataStore.set(key: PlacesConstants.UserDefaults.PERSISTED_LONGITUDE, value: 23.45)
        places.dataStore.set(key: PlacesConstants.UserDefaults.PERSISTED_AUTH_STATUS, value: "always")
        places.dataStore.set(key: PlacesConstants.UserDefaults.PERSISTED_MEMBERSHIP_VALID_UNTIL, value: Date().timeIntervalSince1970 + 60)
    }

    func clearPlacesDataStore() {
        places.dataStore.remove(key: PlacesConstants.UserDefaults.PERSISTED_NEARBY_POIS)
        places.dataStore.remove(key: PlacesConstants.UserDefaults.PERSISTED_USER_WITHIN_POIS)
        places.dataStore.remove(key: PlacesConstants.UserDefaults.PERSISTED_CURRENT_POI)
        places.dataStore.remove(key: PlacesConstants.UserDefaults.PERSISTED_LAST_ENTERED_POI)
        places.dataStore.remove(key: PlacesConstants.UserDefaults.PERSISTED_LAST_EXITED_POI)
        places.dataStore.remove(key: PlacesConstants.UserDefaults.PERSISTED_LATITUDE)
        places.dataStore.remove(key: PlacesConstants.UserDefaults.PERSISTED_LONGITUDE)
        places.dataStore.remove(key: PlacesConstants.UserDefaults.PERSISTED_AUTH_STATUS)
        places.dataStore.remove(key: PlacesConstants.UserDefaults.PERSISTED_MEMBERSHIP_VALID_UNTIL)
    }

    // MARK: - tests

    func testClearClientData() throws {
        // setup
        populatePlacesState()
        populatePlacesDataStore()

        // test
        places.clearClientData()

        // verify
        XCTAssertEqual(0, places.nearbyPois.count)
        XCTAssertEqual(0, places.userWithinPois.count)
        XCTAssertNil(places.currentPoi)
        XCTAssertNil(places.lastEnteredPoi)
        XCTAssertNil(places.lastExitedPoi)
        XCTAssertEqual(PlacesConstants.DefaultValues.INVALID_LAT_LON, places.lastKnownCoordinate.latitude)
        XCTAssertEqual(PlacesConstants.DefaultValues.INVALID_LAT_LON, places.lastKnownCoordinate.longitude)
        XCTAssertEqual(CLAuthorizationStatus.notDetermined, places.authStatus)
        XCTAssertNil(places.membershipValidUntil)

        XCTAssertNil(places.dataStore.getDictionary(key: PlacesConstants.UserDefaults.PERSISTED_NEARBY_POIS))
        XCTAssertNil(places.dataStore.getDictionary(key: PlacesConstants.UserDefaults.PERSISTED_USER_WITHIN_POIS))
        XCTAssertNil(places.dataStore.getString(key: PlacesConstants.UserDefaults.PERSISTED_CURRENT_POI))
        XCTAssertNil(places.dataStore.getString(key: PlacesConstants.UserDefaults.PERSISTED_LAST_ENTERED_POI))
        XCTAssertNil(places.dataStore.getString(key: PlacesConstants.UserDefaults.PERSISTED_LAST_EXITED_POI))
        XCTAssertEqual(PlacesConstants.DefaultValues.INVALID_LAT_LON, places.dataStore.getDouble(key: PlacesConstants.UserDefaults.PERSISTED_LATITUDE))
        XCTAssertEqual(PlacesConstants.DefaultValues.INVALID_LAT_LON, places.dataStore.getDouble(key: PlacesConstants.UserDefaults.PERSISTED_LONGITUDE))
        XCTAssertEqual("unknown", places.dataStore.getString(key: PlacesConstants.UserDefaults.PERSISTED_AUTH_STATUS))
        XCTAssertNil(places.dataStore.getDouble(key: PlacesConstants.UserDefaults.PERSISTED_MEMBERSHIP_VALID_UNTIL))
    }

    func testClearMembershipData() throws {
        // setup
        populatePlacesState()
        populatePlacesDataStore()

        // test
        places.clearMembershipData()

        // verify
        XCTAssertNil(places.currentPoi)
        XCTAssertNil(places.lastEnteredPoi)
        XCTAssertNil(places.lastExitedPoi)
        XCTAssertNil(places.membershipValidUntil)
        XCTAssertNil(places.dataStore.getString(key: PlacesConstants.UserDefaults.PERSISTED_CURRENT_POI))
        XCTAssertNil(places.dataStore.getString(key: PlacesConstants.UserDefaults.PERSISTED_LAST_ENTERED_POI))
        XCTAssertNil(places.dataStore.getString(key: PlacesConstants.UserDefaults.PERSISTED_LAST_EXITED_POI))
        XCTAssertNil(places.dataStore.getDouble(key: PlacesConstants.UserDefaults.PERSISTED_MEMBERSHIP_VALID_UNTIL))

        XCTAssertNotNil(places.dataStore.getDictionary(key: PlacesConstants.UserDefaults.PERSISTED_NEARBY_POIS))
        XCTAssertNotNil(places.dataStore.getDictionary(key: PlacesConstants.UserDefaults.PERSISTED_USER_WITHIN_POIS))
        XCTAssertNotNil(places.dataStore.getDouble(key: PlacesConstants.UserDefaults.PERSISTED_LATITUDE))
        XCTAssertNotNil(places.dataStore.getDouble(key: PlacesConstants.UserDefaults.PERSISTED_LONGITUDE))
        XCTAssertNotNil(places.dataStore.getString(key: PlacesConstants.UserDefaults.PERSISTED_AUTH_STATUS))
    }

    func testGetSharedStateDataHappy() throws {
        // setup
        populatePlacesState()

        // test
        let result = places.getSharedStateData()

        // verify
        XCTAssertEqual(6, result.count)
        let nearby = result[PlacesConstants.SharedStateKey.NEARBY_POIS] as! [[String: Any]]
        XCTAssertEqual(1, nearby.count)
        let nearbypoiJsonString = try? String.init(data: JSONSerialization.data(withJSONObject: nearby.first!), encoding: .utf8)
        let nearbypoi = try! PointOfInterest(jsonString: nearbypoiJsonString!)
        XCTAssertTrue(poi == nearbypoi)
        let current = result[PlacesConstants.SharedStateKey.CURRENT_POI] as! [String: Any]
        XCTAssertEqual(poi.identifier, current[PlacesConstants.EventDataKey.Places.REGION_ID] as! String)
        let lastEntered = result[PlacesConstants.SharedStateKey.LAST_ENTERED_POI] as! [String: Any]
        XCTAssertEqual(poi.identifier, lastEntered[PlacesConstants.EventDataKey.Places.REGION_ID] as! String)
        let lastExited = result[PlacesConstants.SharedStateKey.LAST_EXITED_POI] as! [String: Any]
        XCTAssertEqual(poi.identifier, lastExited[PlacesConstants.EventDataKey.Places.REGION_ID] as! String)
        let auth = result[PlacesConstants.SharedStateKey.AUTH_STATUS] as! String
        XCTAssertEqual("always", auth)
        let validUntil = result[PlacesConstants.SharedStateKey.VALID_UNTIL] as! Double
        XCTAssertTrue(validUntil > Date().timeIntervalSince1970)
    }

    func testGetSharedStateDataMembershipDataExpired() throws {
        // setup
        populatePlacesState()
        places.membershipValidUntil = Date().timeIntervalSince1970 - 60

        // test
        let result = places.getSharedStateData()

        // verify
        XCTAssertEqual(3, result.count)
        let nearby = result[PlacesConstants.SharedStateKey.NEARBY_POIS] as! [[String: Any]]
        XCTAssertEqual(1, nearby.count)
        let nearbypoiJsonString = try? String.init(data: JSONSerialization.data(withJSONObject: nearby.first!), encoding: .utf8)
        let nearbypoi = try! PointOfInterest(jsonString: nearbypoiJsonString!)
        XCTAssertTrue(poi == nearbypoi)
        let auth = result[PlacesConstants.SharedStateKey.AUTH_STATUS] as! String
        XCTAssertEqual("always", auth)
        let validUntil = result[PlacesConstants.SharedStateKey.VALID_UNTIL] as? Double
        XCTAssertEqual(0, validUntil)
    }

    func testGetSharedStateDataEverythingIsEmpty() throws {
        // test
        let result = places.getSharedStateData()

        // verify
        XCTAssertEqual(2, result.count)
        let auth = result[PlacesConstants.SharedStateKey.AUTH_STATUS] as! String
        XCTAssertEqual("unknown", auth)
        let validUntil = result[PlacesConstants.SharedStateKey.VALID_UNTIL] as! Double
        XCTAssertEqual(0, validUntil)
    }

    func testLoadPersistence() throws {
        // setup
        XCTAssertEqual(0, places.nearbyPois.count)
        XCTAssertEqual(0, places.userWithinPois.count)
        XCTAssertNil(places.currentPoi)
        XCTAssertNil(places.lastEnteredPoi)
        XCTAssertNil(places.lastExitedPoi)
        XCTAssertEqual(PlacesConstants.DefaultValues.INVALID_LAT_LON, places.lastKnownCoordinate.latitude)
        XCTAssertEqual(PlacesConstants.DefaultValues.INVALID_LAT_LON, places.lastKnownCoordinate.longitude)
        XCTAssertEqual(CLAuthorizationStatus.notDetermined, places.authStatus)
        XCTAssertNil(places.membershipValidUntil)
        populatePlacesDataStore()

        // test
        places.loadPersistence()

        // verify
        XCTAssertEqual(1, places.nearbyPois.count)
        XCTAssertEqual(1, places.userWithinPois.count)
        XCTAssertNotNil(places.currentPoi)
        XCTAssertNotNil(places.lastEnteredPoi)
        XCTAssertNotNil(places.lastExitedPoi)
        XCTAssertEqual(12.34, places.lastKnownCoordinate.latitude)
        XCTAssertEqual(23.45, places.lastKnownCoordinate.longitude)
        XCTAssertEqual(CLAuthorizationStatus.authorizedAlways, places.authStatus)
        XCTAssertNotNil(places.membershipValidUntil)
    }

    func testProcessNewNearbyPoisHappy() throws {
        // setup
        let pois: [PointOfInterest] = [poi]
        XCTAssertEqual(0, places.nearbyPois.count)
        XCTAssertEqual(0, places.userWithinPois.count)
        XCTAssertNil(places.currentPoi)
        XCTAssertNil(places.lastEnteredPoi)
        XCTAssertNil(places.lastExitedPoi)

        // test
        places.processNewNearbyPois(pois)

        // verify
        XCTAssertEqual(1, places.nearbyPois.count)
        XCTAssertEqual(1, places.userWithinPois.count)
        XCTAssertNotNil(places.currentPoi)
        XCTAssertNotNil(places.lastEnteredPoi)
        XCTAssertNil(places.lastExitedPoi)
        // persistence updated
        XCTAssertNotNil(places.dataStore.getDictionary(key: PlacesConstants.UserDefaults.PERSISTED_NEARBY_POIS))
        XCTAssertNotNil(places.dataStore.getDictionary(key: PlacesConstants.UserDefaults.PERSISTED_USER_WITHIN_POIS))
        XCTAssertNotNil(places.dataStore.getString(key: PlacesConstants.UserDefaults.PERSISTED_CURRENT_POI))
        XCTAssertNotNil(places.dataStore.getString(key: PlacesConstants.UserDefaults.PERSISTED_LAST_ENTERED_POI))
        XCTAssertNil(places.dataStore.getString(key: PlacesConstants.UserDefaults.PERSISTED_LAST_EXITED_POI))
        XCTAssertNotNil(places.dataStore.getDouble(key: PlacesConstants.UserDefaults.PERSISTED_MEMBERSHIP_VALID_UNTIL))
    }

    func testProcessNewNearbyPoisEmptyParameter() throws {
        // setup
        populatePlacesDataStore()
        populatePlacesState()
        let pois: [PointOfInterest] = []

        // test
        places.processNewNearbyPois(pois)

        // verify
        XCTAssertEqual(0, places.nearbyPois.count)
        XCTAssertEqual(0, places.userWithinPois.count)
        XCTAssertNil(places.currentPoi)
        XCTAssertNotNil(places.lastEnteredPoi)
        XCTAssertNotNil(places.lastExitedPoi)
        // persistence updated
        XCTAssertNil(places.dataStore.getDictionary(key: PlacesConstants.UserDefaults.PERSISTED_NEARBY_POIS))
        XCTAssertNil(places.dataStore.getDictionary(key: PlacesConstants.UserDefaults.PERSISTED_USER_WITHIN_POIS))
        XCTAssertNil(places.dataStore.getString(key: PlacesConstants.UserDefaults.PERSISTED_CURRENT_POI))
        XCTAssertNotNil(places.dataStore.getString(key: PlacesConstants.UserDefaults.PERSISTED_LAST_ENTERED_POI))
        XCTAssertNotNil(places.dataStore.getString(key: PlacesConstants.UserDefaults.PERSISTED_LAST_EXITED_POI))
        XCTAssertNotNil(places.dataStore.getDouble(key: PlacesConstants.UserDefaults.PERSISTED_MEMBERSHIP_VALID_UNTIL))
    }

    func testProcessRegionEventEntry() throws {
        // setup
        XCTAssertEqual(0, places.userWithinPois.count)
        XCTAssertNil(places.currentPoi)
        XCTAssertNil(places.lastEnteredPoi)

        // test
        places.processRegionEvent(.entry, forPoi: poi)

        // verify
        XCTAssertEqual(1, places.userWithinPois.count)
        XCTAssertNotNil(places.currentPoi)
        XCTAssertNotNil(places.lastEnteredPoi)
        XCTAssertNotNil(places.dataStore.getDictionary(key: PlacesConstants.UserDefaults.PERSISTED_USER_WITHIN_POIS))
        XCTAssertNotNil(places.dataStore.getString(key: PlacesConstants.UserDefaults.PERSISTED_CURRENT_POI))
        XCTAssertNotNil(places.dataStore.getString(key: PlacesConstants.UserDefaults.PERSISTED_LAST_ENTERED_POI))
        XCTAssertNotNil(places.dataStore.getDouble(key: PlacesConstants.UserDefaults.PERSISTED_MEMBERSHIP_VALID_UNTIL))
    }

    func testProcessRegionEventExit() throws {
        // setup
        places.dataStore.set(key: PlacesConstants.UserDefaults.PERSISTED_USER_WITHIN_POIS, value: [poi.identifier: poi.toJsonString()])
        places.dataStore.set(key: PlacesConstants.UserDefaults.PERSISTED_CURRENT_POI, value: poi.toJsonString())
        places.dataStore.set(key: PlacesConstants.UserDefaults.PERSISTED_LAST_ENTERED_POI, value: poi.toJsonString())

        // test
        places.processRegionEvent(.exit, forPoi: poi)

        // verify
        XCTAssertEqual(0, places.userWithinPois.count)
        XCTAssertNotNil(places.lastExitedPoi)
        XCTAssertNil(places.currentPoi)
        XCTAssertNil(places.dataStore.getDictionary(key: PlacesConstants.UserDefaults.PERSISTED_USER_WITHIN_POIS))
        XCTAssertNil(places.dataStore.getString(key: PlacesConstants.UserDefaults.PERSISTED_CURRENT_POI))
        XCTAssertNotNil(places.dataStore.getString(key: PlacesConstants.UserDefaults.PERSISTED_LAST_EXITED_POI))
        XCTAssertNotNil(places.dataStore.getDouble(key: PlacesConstants.UserDefaults.PERSISTED_MEMBERSHIP_VALID_UNTIL))
    }

    func testUpdateMembershipValidUntil() throws {
        // setup
        places.membershipValidUntil = nil
        places.membershipTtl = 30

        // test
        places.updateMembershipValidUntil()
        let expectedTtl = (Date().timeIntervalSince1970 + 30).rounded()

        // verify
        XCTAssertNotNil(places.membershipValidUntil)
        XCTAssertEqual(expectedTtl, places.membershipValidUntil)
        XCTAssertEqual(expectedTtl, places.dataStore.getDouble(key: PlacesConstants.UserDefaults.PERSISTED_MEMBERSHIP_VALID_UNTIL))
    }
}
