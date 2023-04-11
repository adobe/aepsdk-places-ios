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
import AEPServices
import AEPCore
@testable import AEPPlaces

class PlacesQueryServiceTests: XCTestCase {
    
    let queryService = PlacesQueryService()
    var mockNetworkService = TestableNetworkService()
    var mockLibraryOne = PlacesLibrary(id: "1234", name: "lib1")
    var mockLibraryTwo = PlacesLibrary(id: "2345", name: "lib2")
    var mockEndpoint = "places.mock.endpoint"
    var mockTtl: TimeInterval = 600
    var mockPlacesConfiguration: PlacesConfiguration {
        PlacesConfiguration(libraries: [mockLibraryOne, mockLibraryTwo],
                            endpoint: mockEndpoint,
                            membershipTtl: mockTtl)
    }
            
    override func setUpWithError() throws {
        ServiceProvider.shared.networkService = mockNetworkService
    }
    
    override func tearDownWithError() throws {}
       
    
    // MARK: - Tests
    
    func testGetNearbyPlacesConfigurationNotValid() throws {
        // setup
        let mockLat: Double = 12.34
        let mockLon: Double = 23.45
        let mockCount: Int = 1
        let expectation = XCTestExpectation()
        let invalidConfiguration = PlacesConfiguration(libraries: [], endpoint: "", membershipTtl: 3)
        
        // test
        queryService.getNearbyPlaces(lat: mockLat, lon: mockLon, count: mockCount, configuration: invalidConfiguration) { (result) in
            XCTAssertNotNil(result)
            XCTAssertEqual(PlacesQueryResponseCode.configurationError, result.response)
            XCTAssertNil(result.pois)
            
            expectation.fulfill()
        }
        
        XCTAssertEqual(0, mockNetworkService.requests.count)
        wait(for: [expectation], timeout: 1)
    }
  
    // COVERAGE needed - how can we get the url creation to fail using an invalid PlacesConfiguration?
//    func testGetNearbyPlacesUrlInvalid() throws {
//        // setup
//        let mockLat: Double = 12.34
//        let mockLon: Double = 23.45
//        let mockCount: Int = 1
//        let expectation = XCTestExpectation()
//        let invalidConfiguration = PlacesConfiguration(libraries: [mockLibraryOne], endpoint: "❤️1nval1dUR7%#$❤️/ñ", membershipTtl: 3)
//
//        // test
//        queryService.getNearbyPlaces(lat: mockLat, lon: mockLon, count: mockCount, configuration: invalidConfiguration) { (result) in
//            XCTAssertNotNil(result)
//            XCTAssertEqual(PlacesQueryResponseCode.configurationError, result.response)
//            XCTAssertNil(result.pois)
//
//            expectation.fulfill()
//        }
//
//        XCTAssertEqual(0, mockNetworkService.requests.count)
//        wait(for: [expectation], timeout: 1)
//    }

    func testGetNearbyPlacesResponseNotOK() throws {
        // setup
        let mockLat: Double = 12.34
        let mockLon: Double = 23.45
        let mockCount: Int = 5
        let expectedUrl = "https://places.mock.endpoint/placesedgequery/?library=1234&library=2345&latitude=12.34&longitude=23.45&limit=5"
        let filePath = Bundle(for: PlacesQueryServiceTests.self).url(forResource: "onePoiUserWithin", withExtension: ".json")
        let expectedData = try? Data(contentsOf: filePath!)
        let expectedResponse = HTTPURLResponse(url: URL(string: "https://places.mock.endpoint")!,
                                               statusCode: 404, httpVersion: nil, headerFields: nil)
        mockNetworkService.mockResponse = (data: expectedData, response: expectedResponse, error: nil)
        let expectation = XCTestExpectation()
        
        // test
        queryService.getNearbyPlaces(lat: mockLat, lon: mockLon, count: mockCount, configuration: mockPlacesConfiguration) { (result) in
            XCTAssertNotNil(result)
            XCTAssertEqual(PlacesQueryResponseCode.serverResponseError, result.response)
            XCTAssertNil(result.pois)
            
            expectation.fulfill()
        }
        
        // verify
        XCTAssertEqual(expectedUrl, mockNetworkService.requests[0].url.absoluteString)
        wait(for: [expectation], timeout: 1)
    }
    
    func testGetNearbyPlacesEmptyResponseData() throws {
        // setup
        let mockLat: Double = 12.34
        let mockLon: Double = 23.45
        let mockCount: Int = 5
        let expectedUrl = "https://places.mock.endpoint/placesedgequery/?library=1234&library=2345&latitude=12.34&longitude=23.45&limit=5"
        let expectedResponse = HTTPURLResponse(url: URL(string: "https://places.mock.endpoint")!,
                                               statusCode: 200, httpVersion: nil, headerFields: nil)
        mockNetworkService.mockResponse = (data: nil, response: expectedResponse, error: nil)
        let expectation = XCTestExpectation()
        
        // test
        queryService.getNearbyPlaces(lat: mockLat, lon: mockLon, count: mockCount, configuration: mockPlacesConfiguration) { (result) in
            XCTAssertNotNil(result)
            XCTAssertEqual(PlacesQueryResponseCode.ok, result.response)
            XCTAssertNil(result.pois)
            
            expectation.fulfill()
        }
        
        // verify
        XCTAssertEqual(expectedUrl, mockNetworkService.requests[0].url.absoluteString)
        wait(for: [expectation], timeout: 1)
    }
    
    func testGetNearbyPlacesInvalidJsonInData() throws {
        // setup
        let mockLat: Double = 12.34
        let mockLon: Double = 23.45
        let mockCount: Int = 5
        let expectedUrl = "https://places.mock.endpoint/placesedgequery/?library=1234&library=2345&latitude=12.34&longitude=23.45&limit=5"
        let filePath = Bundle(for: PlacesQueryServiceTests.self).url(forResource: "badJson", withExtension: ".json")
        let expectedData = try? Data(contentsOf: filePath!)
        let expectedResponse = HTTPURLResponse(url: URL(string: "https://places.mock.endpoint")!,
                                               statusCode: 200, httpVersion: nil, headerFields: nil)
        mockNetworkService.mockResponse = (data: expectedData, response: expectedResponse, error: nil)
        let expectation = XCTestExpectation()
        
        // test
        queryService.getNearbyPlaces(lat: mockLat, lon: mockLon, count: mockCount, configuration: mockPlacesConfiguration) { (result) in
            XCTAssertNotNil(result)
            XCTAssertEqual(PlacesQueryResponseCode.serverResponseError, result.response)
            XCTAssertNil(result.pois)
            
            expectation.fulfill()
        }
        
        // verify
        XCTAssertEqual(expectedUrl, mockNetworkService.requests[0].url.absoluteString)
        wait(for: [expectation], timeout: 1)
    }
    
    func testGetNearbyPlacesNoPlacesObjectInJson() throws {
        // setup
        let mockLat: Double = 12.34
        let mockLon: Double = 23.45
        let mockCount: Int = 5
        let expectedUrl = "https://places.mock.endpoint/placesedgequery/?library=1234&library=2345&latitude=12.34&longitude=23.45&limit=5"
        let filePath = Bundle(for: PlacesQueryServiceTests.self).url(forResource: "noPlaces", withExtension: ".json")
        let expectedData = try? Data(contentsOf: filePath!)
        let expectedResponse = HTTPURLResponse(url: URL(string: "https://places.mock.endpoint")!,
                                               statusCode: 200, httpVersion: nil, headerFields: nil)
        mockNetworkService.mockResponse = (data: expectedData, response: expectedResponse, error: nil)
        let expectation = XCTestExpectation()
        
        // test
        queryService.getNearbyPlaces(lat: mockLat, lon: mockLon, count: mockCount, configuration: mockPlacesConfiguration) { (result) in
            XCTAssertNotNil(result)
            XCTAssertEqual(PlacesQueryResponseCode.ok, result.response)
            XCTAssertNil(result.pois)
            
            expectation.fulfill()
        }
        
        // verify
        XCTAssertEqual(expectedUrl, mockNetworkService.requests[0].url.absoluteString)
        wait(for: [expectation], timeout: 1)
    }
    
    func testGetNearbyPlacesOnePoiWithin() throws {
        // setup
        let mockLat: Double = 12.34
        let mockLon: Double = 23.45
        let mockCount: Int = 5
        let expectedUrl = "https://places.mock.endpoint/placesedgequery/?library=1234&library=2345&latitude=12.34&longitude=23.45&limit=5"
        let filePath = Bundle(for: PlacesQueryServiceTests.self).url(forResource: "onePoiUserWithin", withExtension: ".json")
        let expectedData = try? Data(contentsOf: filePath!)
        let expectedResponse = HTTPURLResponse(url: URL(string: "https://places.mock.endpoint")!,
                                               statusCode: 200, httpVersion: nil, headerFields: nil)
        mockNetworkService.mockResponse = (data: expectedData, response: expectedResponse, error: nil)
        let expectation = XCTestExpectation()
        
        // test
        queryService.getNearbyPlaces(lat: mockLat, lon: mockLon, count: mockCount, configuration: mockPlacesConfiguration) { (result) in
            XCTAssertNotNil(result)
            XCTAssertEqual(PlacesQueryResponseCode.ok, result.response)
            XCTAssertEqual(1, result.pois?.count)
            let returnedPoi = result.pois![0]
            XCTAssertEqual("1234", returnedPoi.identifier)
            XCTAssertEqual("myplace", returnedPoi.name)
            XCTAssertEqual(12.34, returnedPoi.latitude)
            XCTAssertEqual(23.45, returnedPoi.longitude)
            XCTAssertEqual(500, returnedPoi.radius)
            XCTAssertTrue(returnedPoi.userIsWithin)
            XCTAssertEqual("mylib", returnedPoi.libraryId)
            XCTAssertEqual(25, returnedPoi.weight)
            XCTAssertEqual("value1", returnedPoi.metaData["key1"] as? String)
            
            expectation.fulfill()
        }
        
        // verify
        XCTAssertEqual(expectedUrl, mockNetworkService.requests[0].url.absoluteString)
        wait(for: [expectation], timeout: 1)
    }
    
    func testGetNearbyPlacesOneWithinNoNearbyInJson() throws {
        // setup
        let mockLat: Double = 12.34
        let mockLon: Double = 23.45
        let mockCount: Int = 5
        let expectedUrl = "https://places.mock.endpoint/placesedgequery/?library=1234&library=2345&latitude=12.34&longitude=23.45&limit=5"
        let filePath = Bundle(for: PlacesQueryServiceTests.self).url(forResource: "noNearbyPoiInJson", withExtension: ".json")
        let expectedData = try? Data(contentsOf: filePath!)
        let expectedResponse = HTTPURLResponse(url: URL(string: "https://places.mock.endpoint")!,
                                               statusCode: 200, httpVersion: nil, headerFields: nil)
        mockNetworkService.mockResponse = (data: expectedData, response: expectedResponse, error: nil)
        let expectation = XCTestExpectation()
        
        // test
        queryService.getNearbyPlaces(lat: mockLat, lon: mockLon, count: mockCount, configuration: mockPlacesConfiguration) { (result) in
            XCTAssertNotNil(result)
            XCTAssertEqual(PlacesQueryResponseCode.ok, result.response)
            XCTAssertEqual(1, result.pois?.count)
            let returnedPoi = result.pois![0]
            XCTAssertEqual("1234", returnedPoi.identifier)
            XCTAssertEqual("myplace", returnedPoi.name)
            XCTAssertEqual(12.34, returnedPoi.latitude)
            XCTAssertEqual(23.45, returnedPoi.longitude)
            XCTAssertEqual(500, returnedPoi.radius)
            XCTAssertTrue(returnedPoi.userIsWithin)
            XCTAssertEqual("mylib", returnedPoi.libraryId)
            XCTAssertEqual(25, returnedPoi.weight)
            XCTAssertEqual("value1", returnedPoi.metaData["key1"] as? String)
            
            expectation.fulfill()
        }
        
        // verify
        XCTAssertEqual(expectedUrl, mockNetworkService.requests[0].url.absoluteString)
        wait(for: [expectation], timeout: 1)
    }
    
    func testGetNearbyPlacesOneNearbyNoUserWithinInJson() throws {
        // setup
        let mockLat: Double = 12.34
        let mockLon: Double = 23.45
        let mockCount: Int = 5
        let expectedUrl = "https://places.mock.endpoint/placesedgequery/?library=1234&library=2345&latitude=12.34&longitude=23.45&limit=5"
        let filePath = Bundle(for: PlacesQueryServiceTests.self).url(forResource: "noUserWithinPoiInJson", withExtension: ".json")
        let expectedData = try? Data(contentsOf: filePath!)
        let expectedResponse = HTTPURLResponse(url: URL(string: "https://places.mock.endpoint")!,
                                               statusCode: 200, httpVersion: nil, headerFields: nil)
        mockNetworkService.mockResponse = (data: expectedData, response: expectedResponse, error: nil)
        let expectation = XCTestExpectation()
        
        // test
        queryService.getNearbyPlaces(lat: mockLat, lon: mockLon, count: mockCount, configuration: mockPlacesConfiguration) { (result) in
            XCTAssertNotNil(result)
            XCTAssertEqual(PlacesQueryResponseCode.ok, result.response)
            XCTAssertEqual(1, result.pois?.count)
            let returnedPoi = result.pois![0]
            XCTAssertEqual("1234", returnedPoi.identifier)
            XCTAssertEqual("myplace", returnedPoi.name)
            XCTAssertEqual(12.34, returnedPoi.latitude)
            XCTAssertEqual(23.45, returnedPoi.longitude)
            XCTAssertEqual(500, returnedPoi.radius)
            XCTAssertFalse(returnedPoi.userIsWithin)
            XCTAssertEqual("mylib", returnedPoi.libraryId)
            XCTAssertEqual(25, returnedPoi.weight)
            XCTAssertEqual("value1", returnedPoi.metaData["key1"] as? String)
            
            expectation.fulfill()
        }
        
        // verify
        XCTAssertEqual(expectedUrl, mockNetworkService.requests[0].url.absoluteString)
        wait(for: [expectation], timeout: 1)
    }
    
    func testGetNearbyPlacesOneNearby() throws {
        // setup
        let mockLat: Double = 12.34
        let mockLon: Double = 23.45
        let mockCount: Int = 5
        let expectedUrl = "https://places.mock.endpoint/placesedgequery/?library=1234&library=2345&latitude=12.34&longitude=23.45&limit=5"
        let filePath = Bundle(for: PlacesQueryServiceTests.self).url(forResource: "onePoiNearby", withExtension: ".json")
        let expectedData = try? Data(contentsOf: filePath!)
        let expectedResponse = HTTPURLResponse(url: URL(string: "https://places.mock.endpoint")!,
                                               statusCode: 200, httpVersion: nil, headerFields: nil)
        mockNetworkService.mockResponse = (data: expectedData, response: expectedResponse, error: nil)
        let expectation = XCTestExpectation()
        
        // test
        queryService.getNearbyPlaces(lat: mockLat, lon: mockLon, count: mockCount, configuration: mockPlacesConfiguration) { (result) in
            XCTAssertNotNil(result)
            XCTAssertEqual(PlacesQueryResponseCode.ok, result.response)
            XCTAssertEqual(1, result.pois?.count)
            let returnedPoi = result.pois![0]
            XCTAssertEqual("1234", returnedPoi.identifier)
            XCTAssertEqual("myplace", returnedPoi.name)
            XCTAssertEqual(12.34, returnedPoi.latitude)
            XCTAssertEqual(23.45, returnedPoi.longitude)
            XCTAssertEqual(500, returnedPoi.radius)
            XCTAssertFalse(returnedPoi.userIsWithin)
            XCTAssertEqual("mylib", returnedPoi.libraryId)
            XCTAssertEqual(25, returnedPoi.weight)
            XCTAssertEqual("value1", returnedPoi.metaData["key1"] as? String)
            
            expectation.fulfill()
        }
        
        // verify
        XCTAssertEqual(expectedUrl, mockNetworkService.requests[0].url.absoluteString)
        wait(for: [expectation], timeout: 1)
    }
    
    func testGetNearbyPlacesOnePoiNearbyOneUserWithin() throws {
        // setup
        let mockLat: Double = 12.34
        let mockLon: Double = 23.45
        let mockCount: Int = 5
        let expectedUrl = "https://places.mock.endpoint/placesedgequery/?library=1234&library=2345&latitude=12.34&longitude=23.45&limit=5"
        let filePath = Bundle(for: PlacesQueryServiceTests.self).url(forResource: "onePoiUserWithinOneNearby", withExtension: ".json")
        let expectedData = try? Data(contentsOf: filePath!)
        let expectedResponse = HTTPURLResponse(url: URL(string: "https://places.mock.endpoint")!,
                                               statusCode: 200, httpVersion: nil, headerFields: nil)
        mockNetworkService.mockResponse = (data: expectedData, response: expectedResponse, error: nil)
        let expectation = XCTestExpectation()
        
        // test
        queryService.getNearbyPlaces(lat: mockLat, lon: mockLon, count: mockCount, configuration: mockPlacesConfiguration) { (result) in
            XCTAssertNotNil(result)
            XCTAssertEqual(PlacesQueryResponseCode.ok, result.response)
            XCTAssertEqual(2, result.pois?.count)
            
            let returnedPoi = result.pois![0]
            XCTAssertEqual("1234", returnedPoi.identifier)
            XCTAssertEqual("myplace", returnedPoi.name)
            XCTAssertEqual(12.34, returnedPoi.latitude)
            XCTAssertEqual(23.45, returnedPoi.longitude)
            XCTAssertEqual(500, returnedPoi.radius)
            XCTAssertTrue(returnedPoi.userIsWithin)
            XCTAssertEqual("mylib", returnedPoi.libraryId)
            XCTAssertEqual(25, returnedPoi.weight)
            XCTAssertEqual("value1", returnedPoi.metaData["key1"] as? String)
            
            let nearbyPoi = result.pois![1]
            XCTAssertEqual("2345", nearbyPoi.identifier)
            XCTAssertEqual("yourplace", nearbyPoi.name)
            XCTAssertEqual(23.45, nearbyPoi.latitude)
            XCTAssertEqual(34.56, nearbyPoi.longitude)
            XCTAssertEqual(300, nearbyPoi.radius)
            XCTAssertFalse(nearbyPoi.userIsWithin)
            XCTAssertEqual("yourlib", nearbyPoi.libraryId)
            XCTAssertEqual(30, nearbyPoi.weight)
            XCTAssertEqual("value2", nearbyPoi.metaData["key2"] as? String)
            
            expectation.fulfill()
        }
        
        // verify
        XCTAssertEqual(expectedUrl, mockNetworkService.requests[0].url.absoluteString)
        wait(for: [expectation], timeout: 1)
    }
    
    func testGetNearbyPlacesTwoNearby() throws {
        // setup
        let mockLat: Double = 12.34
        let mockLon: Double = 23.45
        let mockCount: Int = 5
        let expectedUrl = "https://places.mock.endpoint/placesedgequery/?library=1234&library=2345&latitude=12.34&longitude=23.45&limit=5"
        let filePath = Bundle(for: PlacesQueryServiceTests.self).url(forResource: "twoPoiNearby", withExtension: ".json")
        let expectedData = try? Data(contentsOf: filePath!)
        let expectedResponse = HTTPURLResponse(url: URL(string: "https://places.mock.endpoint")!,
                                               statusCode: 200, httpVersion: nil, headerFields: nil)
        mockNetworkService.mockResponse = (data: expectedData, response: expectedResponse, error: nil)
        let expectation = XCTestExpectation()
        
        // test
        queryService.getNearbyPlaces(lat: mockLat, lon: mockLon, count: mockCount, configuration: mockPlacesConfiguration) { (result) in
            XCTAssertNotNil(result)
            XCTAssertEqual(PlacesQueryResponseCode.ok, result.response)
            XCTAssertEqual(2, result.pois?.count)
            
            let poi1 = result.pois![0]
            XCTAssertEqual("1234", poi1.identifier)
            XCTAssertEqual("myplace", poi1.name)
            XCTAssertEqual(12.34, poi1.latitude)
            XCTAssertEqual(23.45, poi1.longitude)
            XCTAssertEqual(500, poi1.radius)
            XCTAssertFalse(poi1.userIsWithin)
            XCTAssertEqual("mylib", poi1.libraryId)
            XCTAssertEqual(25, poi1.weight)
            XCTAssertEqual("value1", poi1.metaData["key1"] as? String)
            
            let poi2 = result.pois![1]
            XCTAssertEqual("2345", poi2.identifier)
            XCTAssertEqual("yourplace", poi2.name)
            XCTAssertEqual(23.45, poi2.latitude)
            XCTAssertEqual(34.56, poi2.longitude)
            XCTAssertEqual(300, poi2.radius)
            XCTAssertFalse(poi2.userIsWithin)
            XCTAssertEqual("yourlib", poi2.libraryId)
            XCTAssertEqual(30, poi2.weight)
            XCTAssertEqual("value2", poi2.metaData["key2"] as? String)
            
            expectation.fulfill()
        }
        
        // verify
        XCTAssertEqual(expectedUrl, mockNetworkService.requests[0].url.absoluteString)
        wait(for: [expectation], timeout: 1)
    }
    
    func testGetNearbyPlacesTwoUserWithin() throws {
        // setup
        let mockLat: Double = 12.34
        let mockLon: Double = 23.45
        let mockCount: Int = 5
        let expectedUrl = "https://places.mock.endpoint/placesedgequery/?library=1234&library=2345&latitude=12.34&longitude=23.45&limit=5"
        let filePath = Bundle(for: PlacesQueryServiceTests.self).url(forResource: "twoPoiUserWithin", withExtension: ".json")
        let expectedData = try? Data(contentsOf: filePath!)
        let expectedResponse = HTTPURLResponse(url: URL(string: "https://places.mock.endpoint")!,
                                               statusCode: 200, httpVersion: nil, headerFields: nil)
        mockNetworkService.mockResponse = (data: expectedData, response: expectedResponse, error: nil)
        let expectation = XCTestExpectation()
        
        // test
        queryService.getNearbyPlaces(lat: mockLat, lon: mockLon, count: mockCount, configuration: mockPlacesConfiguration) { (result) in
            XCTAssertNotNil(result)
            XCTAssertEqual(PlacesQueryResponseCode.ok, result.response)
            XCTAssertEqual(2, result.pois?.count)
            
            let poi1 = result.pois![0]
            XCTAssertEqual("1234", poi1.identifier)
            XCTAssertEqual("myplace", poi1.name)
            XCTAssertEqual(12.34, poi1.latitude)
            XCTAssertEqual(23.45, poi1.longitude)
            XCTAssertEqual(500, poi1.radius)
            XCTAssertTrue(poi1.userIsWithin)
            XCTAssertEqual("mylib", poi1.libraryId)
            XCTAssertEqual(25, poi1.weight)
            XCTAssertEqual("value1", poi1.metaData["key1"] as? String)
            
            let poi2 = result.pois![1]
            XCTAssertEqual("2345", poi2.identifier)
            XCTAssertEqual("yourplace", poi2.name)
            XCTAssertEqual(23.45, poi2.latitude)
            XCTAssertEqual(34.56, poi2.longitude)
            XCTAssertEqual(300, poi2.radius)
            XCTAssertTrue(poi2.userIsWithin)
            XCTAssertEqual("yourlib", poi2.libraryId)
            XCTAssertEqual(30, poi2.weight)
            XCTAssertEqual("value2", poi2.metaData["key2"] as? String)
            
            expectation.fulfill()
        }
        
        // verify
        XCTAssertEqual(expectedUrl, mockNetworkService.requests[0].url.absoluteString)
        wait(for: [expectation], timeout: 1)
    }
}
