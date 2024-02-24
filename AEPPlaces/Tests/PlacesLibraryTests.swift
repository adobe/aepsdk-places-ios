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
import AEPTestUtils

class PlacesLibraryTests: XCTestCase, AnyCodableAsserts {
    
    static let mockLibraryId = "552"
    static let mockLibraryName = "myLibrary"
       
    // MARK: - Helpers
    func getMockLibrary(libraryId: String = mockLibraryId, name: String = mockLibraryName) -> PlacesLibrary {
        return PlacesLibrary(id: libraryId, name: name)
    }
    
    // MARK: - Tests
    func testConstructor() throws {
        // setup
        let library = PlacesLibrary(id: "1234", name: "niner")
        
        // verify
        XCTAssertNotNil(library)
        XCTAssertEqual("1234", library.id)
        XCTAssertEqual("niner", library.name)
    }
    
    func testGetLibrary() throws {
        // setup
        let library = getMockLibrary()
        
        // verify
        XCTAssertEqual(PlacesLibraryTests.mockLibraryId, library.id)
    }
    
    func testGetName() throws {
        // setup
        let library = getMockLibrary()
        
        // verify
        XCTAssertEqual(PlacesLibraryTests.mockLibraryName, library.name)
    }
    
    func testPlacesLibraryFromJsonStringHappy() throws {
        // setup
        let jsonString = "{\"id\":\"\(PlacesLibraryTests.mockLibraryId)\", \"name\":\"\(PlacesLibraryTests.mockLibraryName)\"}"
        
        // test
        let library = PlacesLibrary.fromJsonString(jsonString)
        
        // verify
        XCTAssertNotNil(library)
        XCTAssertEqual(PlacesLibraryTests.mockLibraryId, library?.id)
        XCTAssertEqual(PlacesLibraryTests.mockLibraryName, library?.name)
    }
    
    func testPlacesLibraryFromJsonStringBadJson() throws {
        // setup
        let jsonString = "i'm not json"
        
        // test
        let library = PlacesLibrary.fromJsonString(jsonString)
        
        // verify
        XCTAssertNil(library)
    }
    
    func testPlacesLibraryFromJsonStringMissingLibraryId() throws {
        // setup
        let jsonString = "{\"name\":\"\(PlacesLibraryTests.mockLibraryName)\"}"
        
        // test
        let library = PlacesLibrary.fromJsonString(jsonString)
        
        // verify
        XCTAssertNil(library)
    }
    
    func testPlacesLibraryFromJsonStringMissingName() throws {
        // setup
        let jsonString = "{\"id\":\"\(PlacesLibraryTests.mockLibraryId)\"}"
        
        // test
        let library = PlacesLibrary.fromJsonString(jsonString)
        
        // verify
        XCTAssertNil(library)
    }
    
    func testPlacesLibraryFromJsonStringEmptyString() throws {
        // setup
        let jsonString = ""
        
        // test
        let library = PlacesLibrary.fromJsonString(jsonString)
        
        // verify
        XCTAssertNil(library)
    }
    
    func testToJsonString() throws {
        // setup
        let library = getMockLibrary()
        let expectedString = "{\"id\":\"552\",\"name\":\"myLibrary\"}"
        
        // test
        let jsonString = library.toJsonString()
        
        // verify
        assertExactMatch(expected: expectedString.toAnyCodable()!, actual: jsonString?.toAnyCodable(), pathOptions: [])
    }
    
    
}
