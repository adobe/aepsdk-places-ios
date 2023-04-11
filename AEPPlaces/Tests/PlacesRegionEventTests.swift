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

class PlacesRegionEventTests: XCTestCase {
   
    // MARK: - Tests
    
    func testConstructorRawValuesEntry() throws {
        // setup
        let entryEvent = PlacesRegionEvent(rawValue: 0)
        
        // verify
        XCTAssertEqual(PlacesRegionEvent.entry, entryEvent)
    }
    
    func testConstructorRawValuesExit() throws {
        // setup
        let exitEvent = PlacesRegionEvent(rawValue: 1)
        
        // verify
        XCTAssertEqual(PlacesRegionEvent.exit, exitEvent)
    }
        
    func testConstructorRawValuesInvalid() throws {
        // setup
        let unmatchedEvent = PlacesRegionEvent(rawValue: 552)
        
        // verify
        XCTAssertNil(unmatchedEvent)
    }
    
    func testFromStringEntry() throws {
        // setup
        let entry = PlacesRegionEvent.fromString("entry")
        
        // verify
        XCTAssertEqual(PlacesRegionEvent.entry, entry)
    }
    
    func testFromStringExit() throws {
        // setup
        let exit = PlacesRegionEvent.fromString("exit")
        
        // verify
        XCTAssertEqual(PlacesRegionEvent.exit, exit)
    }
    
    func testFromStringInvalid() throws {
        // setup
        let invalid = PlacesRegionEvent.fromString("i don't match anything")
        
        // verify
        XCTAssertNil(invalid)
    }
        
    func testStringValues() throws {
        // verify
        XCTAssertEqual("entry", PlacesRegionEvent.entry.stringValue)
        XCTAssertEqual("exit", PlacesRegionEvent.exit.stringValue)
    }
    
    func testToExperienceEventTypeEntry() throws {
        // setup
        let entryEvent = PlacesRegionEvent(rawValue: 0)
        
        // verify
        XCTAssertEqual(PlacesConstants.XDM.Location.EventType.ENTRY, entryEvent?.toExperienceEventType())
    }
    
    func testToExperienceEventTypeExit() throws {
        // setup
        let entryEvent = PlacesRegionEvent(rawValue: 1)
        
        // verify
        XCTAssertEqual(PlacesConstants.XDM.Location.EventType.EXIT, entryEvent?.toExperienceEventType())
    }
    
    func testToExperienceEventTypeInvalid() throws {
        // setup
        let entryEvent = PlacesRegionEvent(rawValue: 552)
        
        // verify
        XCTAssertNil(entryEvent?.toExperienceEventType())
    }
}
