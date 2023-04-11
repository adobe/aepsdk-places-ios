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
@testable import AEPCore

class SharedStateResultPlusPlacesTests: XCTestCase {
    // MARK: - Helpers
    func getConfigSharedState(placesLibraries: [[String: Any]]? = [["id":"1234","name":"mylib"], ["id":"2345","name":"yourlib"]],
                              placesEndpoint: String? = "test.places.edge",
                              placesMembershipTtl: TimeInterval? = 552,
                              privacy: String? = "optedin",
                              badPrivacy: Int? = 0,
                              datasetId: String? = "1234") -> SharedStateResult {
        var dataMap: [String: Any] = [:]
        
        if placesLibraries != nil {
            dataMap[PlacesConstants.EventDataKey.Configuration.PLACES_LIBRARIES] = placesLibraries
        }
        if placesEndpoint != nil {
            dataMap[PlacesConstants.EventDataKey.Configuration.PLACES_ENDPOINT] = placesEndpoint
        }
        if placesMembershipTtl != nil {
            dataMap[PlacesConstants.EventDataKey.Configuration.PLACES_MEMBERSHIP_TTL] = placesMembershipTtl
        }
        if privacy != nil {
            dataMap[PlacesConstants.EventDataKey.Configuration.GLOBAL_CONFIG_PRIVACY] = privacy
        }
        if badPrivacy == 552 {
            dataMap[PlacesConstants.EventDataKey.Configuration.GLOBAL_CONFIG_PRIVACY] = badPrivacy
        }
        if datasetId != nil {
            dataMap[PlacesConstants.SharedState.Configuration.EXPERIENCE_EVENT_DATASET] = datasetId
        }
        
        return SharedStateResult(status: .set, value: dataMap)
    }
    
    // MARK: - Tests
    func testPlacesLibrariesHappy() throws {
        // setup
        let state = getConfigSharedState()
        
        // verify
        XCTAssertNotNil(state.placesLibraries)
        XCTAssertEqual(2, state.placesLibraries?.count)
    }
    
    func testPlacesLibrariesEmpty() throws {
        // setup
        let state = getConfigSharedState(placesLibraries: nil)
        
        // verify
        XCTAssertNil(state.placesLibraries)
    }
    
    func testPlacesEndpointHappy() throws {
        // setup
        let state = getConfigSharedState()
        
        // verify
        XCTAssertNotNil(state.placesEndpoint)
        XCTAssertEqual("test.places.edge", state.placesEndpoint!)
    }
    
    func testPlacesEndpointEmpty() throws {
        // setup
        let state = getConfigSharedState(placesEndpoint: nil)
        
        // verify
        XCTAssertNil(state.placesEndpoint)
    }
    
    func testPlacesMembershipTtlHappy() throws {
        // setup
        let state = getConfigSharedState()
        
        // verify
        XCTAssertNotNil(state.placesMembershipTtl)
        XCTAssertEqual(552, state.placesMembershipTtl!)
    }
    
    func testPlacesMembershipTtlEmpty() throws {
        // setup
        let state = getConfigSharedState(placesMembershipTtl: nil)
        
        // verify
        XCTAssertNil(state.placesMembershipTtl)
    }
    
    func testGlobalPrivacyHappy() throws {
        // setup
        let state = getConfigSharedState()
        
        // verify
        XCTAssertEqual(.optedIn, state.globalPrivacy)
    }
    
    func testGlobalPrivacyEmpty() throws {
        // setup
        let state = getConfigSharedState(privacy: nil)
        
        // verify
        XCTAssertEqual(.unknown, state.globalPrivacy)
    }
    
    func testGlobalPrivacyNotString() throws {
        // setup
        let state = getConfigSharedState(badPrivacy: 552)
        
        // verify
        XCTAssertEqual(.unknown, state.globalPrivacy)
    }
    
    func testExperienceEventDatasetHappy() throws {
        // setup
        let state = getConfigSharedState()
        
        // verify
        XCTAssertNotNil(state.experienceEventDataset)
        XCTAssertEqual("1234", state.experienceEventDataset!)
    }
    
    func testExperienceEventDatasetEmpty() throws {
        // setup
        let state = getConfigSharedState(datasetId : nil)
        
        // verify
        XCTAssertNil(state.experienceEventDataset)
    }
    
}
