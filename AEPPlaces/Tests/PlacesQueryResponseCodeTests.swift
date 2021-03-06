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

class PlacesQueryResponseCodeTests: XCTestCase {
    // MARK: - Tests
    
    func testRawValues() throws {
        // verify
        XCTAssertEqual(0, PlacesQueryResponseCode.ok.rawValue)
        XCTAssertEqual(1, PlacesQueryResponseCode.connectivityError.rawValue)
        XCTAssertEqual(2, PlacesQueryResponseCode.serverResponseError.rawValue)
        XCTAssertEqual(3, PlacesQueryResponseCode.invalidLatLongError.rawValue)
        XCTAssertEqual(4, PlacesQueryResponseCode.configurationError.rawValue)
        XCTAssertEqual(5, PlacesQueryResponseCode.queryServiceUnavailable.rawValue)
        XCTAssertEqual(6, PlacesQueryResponseCode.privacyOptedOut.rawValue)
        XCTAssertEqual(7, PlacesQueryResponseCode.unknownError.rawValue)
    }
    
    func testIntFromRawValueOk() throws {
        // setup
        let result = PlacesQueryResponseCode(fromRawValue: 0)
        
        // verify
        XCTAssertEqual(.ok, result)
    }
    
    func testIntFromRawValueConnectivityError() throws {
        // setup
        let result = PlacesQueryResponseCode(fromRawValue: 1)
        
        // verify
        XCTAssertEqual(.connectivityError, result)
    }
    
    func testIntFromRawValueServerResponseError() throws {
        // setup
        let result = PlacesQueryResponseCode(fromRawValue: 2)
        
        // verify
        XCTAssertEqual(.serverResponseError, result)
    }
    
    func testIntFromRawValueInvalidLatLongError() throws {
        // setup
        let result = PlacesQueryResponseCode(fromRawValue: 3)
        
        // verify
        XCTAssertEqual(.invalidLatLongError, result)
    }
    
    func testIntFromRawValueConfigurationError() throws {
        // setup
        let result = PlacesQueryResponseCode(fromRawValue: 4)
        
        // verify
        XCTAssertEqual(.configurationError, result)
    }
    
    func testIntFromRawValueQueryServiceUnavailable() throws {
        // setup
        let result = PlacesQueryResponseCode(fromRawValue: 5)
        
        // verify
        XCTAssertEqual(.queryServiceUnavailable, result)
    }
    
    func testIntFromRawValuePrivacyOptedOut() throws {
        // setup
        let result = PlacesQueryResponseCode(fromRawValue: 6)
        
        // verify
        XCTAssertEqual(.privacyOptedOut, result)
    }
    
    func testIntFromRawValueUnknownError() throws {
        // setup
        let result = PlacesQueryResponseCode(fromRawValue: 7)
        
        // verify
        XCTAssertEqual(.unknownError, result)
    }
    
    func testIntFromRawValueInvalidEnumValue() throws {
        // setup
        let result = PlacesQueryResponseCode(fromRawValue: 552)
        
        // verify
        XCTAssertEqual(.unknownError, result)
    }
}
