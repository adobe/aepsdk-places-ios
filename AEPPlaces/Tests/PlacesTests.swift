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
@testable import AEPCore
@testable import AEPPlaces
@testable import AEPServices

class PlacesTests: XCTestCase {

    var places: Places!
    var mockRuntime: TestableExtensionRuntime!
    var mockQueryService: MockPlacesQueryService!
    var mockNetworkService: MockNetworkServiceOverrider!
    var poi: PointOfInterest = try! PointOfInterest(jsonString: JSON_STRING)
    var poi2: PointOfInterest = try! PointOfInterest(jsonString: JSON_STRING2)
    
    static let JSON_STRING = """
        {"regionid": "1234", "regionname": "myplace", "latitude": 12.34, "longitude": 23.45,
        "radius": 500, "weight": 25, "libraryid": "mylib", "useriswithin": true, "regionmetadata": {"key1": "value1"}}
    """
    static let JSON_STRING2 = """
        {"regionid": "2345", "regionname": "yourplace", "latitude": 23.45, "longitude": 34.56,
        "radius": 100, "weight": 50, "libraryid": "yourlib", "useriswithin": false, "regionmetadata": {"key2": "value2"}}
    """
    
    override func setUpWithError() throws {
        mockNetworkService = MockNetworkServiceOverrider()
        mockRuntime = TestableExtensionRuntime()
        mockQueryService = MockPlacesQueryService()
        
        ServiceProvider.shared.namedKeyValueService = MockDataStore()
        ServiceProvider.shared.networkService = mockNetworkService
        
        places = Places(runtime: mockRuntime, queryService: mockQueryService)
        populatePlacesDataStore()
        places.onRegistered()
    }

    override func tearDownWithError() throws {
        clearPlacesDataStore()
    }
    
    // MARK: - Helpers
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
        places.dataStore.set(key: PlacesConstants.UserDefaults.PERSISTED_NEARBY_POIS,
                             value: [poi.identifier: poi.toJsonString(), poi2.identifier: poi2.toJsonString()])
        places.dataStore.set(key: PlacesConstants.UserDefaults.PERSISTED_USER_WITHIN_POIS, value: [poi.identifier: poi.toJsonString()])
        places.dataStore.set(key: PlacesConstants.UserDefaults.PERSISTED_CURRENT_POI, value: poi.toJsonString())
        places.dataStore.set(key: PlacesConstants.UserDefaults.PERSISTED_LAST_ENTERED_POI, value: poi.toJsonString())
        places.dataStore.set(key: PlacesConstants.UserDefaults.PERSISTED_LAST_EXITED_POI, value: poi.toJsonString())
        places.dataStore.set(key: PlacesConstants.UserDefaults.PERSISTED_LATITUDE, value: 12.34)
        places.dataStore.set(key: PlacesConstants.UserDefaults.PERSISTED_LONGITUDE, value: 23.45)
        places.dataStore.set(key: PlacesConstants.UserDefaults.PERSISTED_AUTH_STATUS, value: "unknown")
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
    
    func getConfigSharedStateEvent() -> Event {
        let configEvent = Event(name: "Shared State",
                                type: EventType.hub,
                                source: EventSource.sharedState,
                                data: [PlacesConstants.EventDataKey.SHARED_STATE_OWNER:
                                       PlacesConstants.EventDataKey.Configuration.SHARED_STATE_NAME])
        return configEvent
    }
    
    func getConfigSharedStateEventData(privacy: PrivacyStatus,
                                       datasetId: String? = "datasetId") -> [String : Any] {
        return [
            PlacesConstants.EventDataKey.Configuration.GLOBAL_CONFIG_PRIVACY: privacy.rawValue,
            PlacesConstants.EventDataKey.Configuration.PLACES_ENDPOINT: "test.places.endpoint",
            PlacesConstants.EventDataKey.Configuration.PLACES_MEMBERSHIP_TTL: 60,
            PlacesConstants.EventDataKey.Configuration.PLACES_LIBRARIES: [
                [PlacesConstants.EventDataKey.Configuration.PLACES_LIBRARY_ID: "libraryId"]
            ],
            PlacesConstants.SharedState.Configuration.EXPERIENCE_EVENT_DATASET: datasetId as Any
        ] as [String : Any]
    }
    
    func prepareConfig(privacy: PrivacyStatus) {
        mockRuntime.simulateSharedState(for: PlacesConstants.EventDataKey.Configuration.SHARED_STATE_NAME,
                                        data: (getConfigSharedStateEventData(privacy: privacy), .set))
    }
    
    func prepareConfigMissingPlaces() {
        mockRuntime.simulateSharedState(for: PlacesConstants.EventDataKey.Configuration.SHARED_STATE_NAME,
                                        data: ([PlacesConstants.EventDataKey.Configuration.GLOBAL_CONFIG_PRIVACY: PrivacyStatus.optedIn.rawValue], .set))
    }
    
    func prepareConfigInvalidPlaces() {
        mockRuntime.simulateSharedState(for: PlacesConstants.EventDataKey.Configuration.SHARED_STATE_NAME,
                                        data: ([
                                            PlacesConstants.EventDataKey.Configuration.GLOBAL_CONFIG_PRIVACY: PrivacyStatus.optedIn.rawValue,
                                            PlacesConstants.EventDataKey.Configuration.PLACES_ENDPOINT: "",
                                            PlacesConstants.EventDataKey.Configuration.PLACES_LIBRARIES: []
                                        ], .set))
    }
    
    func prepareConfigWithDataset(datasetId: String?) {
        mockRuntime.simulateSharedState(for: PlacesConstants.EventDataKey.Configuration.SHARED_STATE_NAME,
                                        data: (getConfigSharedStateEventData(privacy: PrivacyStatus.optedIn, datasetId: datasetId), .set))
    }
    
    func prepareConfigMissingDataset() {
        mockRuntime.simulateSharedState(for: PlacesConstants.EventDataKey.Configuration.SHARED_STATE_NAME,
                                        data: ([
                                            PlacesConstants.EventDataKey.Configuration.GLOBAL_CONFIG_PRIVACY: PrivacyStatus.optedIn.rawValue,
                                            PlacesConstants.EventDataKey.Configuration.PLACES_ENDPOINT: "test.places.endpoint",
                                            PlacesConstants.EventDataKey.Configuration.PLACES_MEMBERSHIP_TTL: 60,
                                            PlacesConstants.EventDataKey.Configuration.PLACES_LIBRARIES: [
                                                [PlacesConstants.EventDataKey.Configuration.PLACES_LIBRARY_ID: "libraryId"]
                                            ]
                                        ], .set))
    }
    
    
    func getGetNearbyPlacesRequestEvent(_ data: [String: Any]? = nil) -> Event {
        return Event(name: PlacesConstants.EventName.Request.GET_NEARBY_PLACES,
                     type: EventType.places,
                     source: EventSource.requestContent,
                     data: data ?? [
                        PlacesConstants.EventDataKey.Places.LATITUDE: 12.34,
                        PlacesConstants.EventDataKey.Places.LONGITUDE: 23.45,
                        PlacesConstants.EventDataKey.Places.COUNT: 7,
                        PlacesConstants.EventDataKey.Places.REQUEST_TYPE: PlacesConstants.EventDataKey.Places.RequestType.GET_NEARBY_PLACES
                     ])
    }
    
    func getProcessRegionEvent(_ data: [String: Any]? = nil,
                               regionEventType: String = PlacesRegionEvent.entry.stringValue) -> Event {
        return Event(name: PlacesConstants.EventName.Request.PROCESS_REGION_EVENT,
                     type: EventType.places,
                     source: EventSource.requestContent,
                     data: data ?? [
                        PlacesConstants.EventDataKey.Places.REGION_ID: "1234",
                        PlacesConstants.EventDataKey.Places.REGION_EVENT_TYPE: regionEventType,
                        PlacesConstants.EventDataKey.Places.REQUEST_TYPE: PlacesConstants.EventDataKey.Places.RequestType.PROCESS_REGION_EVENT
                     ])
    }
    
    func getUserWithinPlacesRequestEvent() -> Event {
        return Event(name: PlacesConstants.EventName.Request.GET_USER_WITHIN_PLACES,
                     type: EventType.places,
                     source: EventSource.requestContent,
                     data: [
                        PlacesConstants.EventDataKey.Places.REQUEST_TYPE: PlacesConstants.EventDataKey.Places.RequestType.GET_USER_WITHIN_PLACES
                     ])
    }
    
    func getLastKnownLocationRequestEvent() -> Event {
        return Event(name: PlacesConstants.EventName.Request.GET_LAST_KNOWN_LOCATION,
                     type: EventType.places,
                     source: EventSource.requestContent,
                     data: [
                        PlacesConstants.EventDataKey.Places.REQUEST_TYPE: PlacesConstants.EventDataKey.Places.RequestType.GET_LAST_KNOWN_LOCATION
                     ])
    }
    
    func getSetAuthorizationStatusRequestEvent(_ data: [String: Any]? = nil) -> Event {
        return Event(name: PlacesConstants.EventName.Request.SET_AUTHORIZATION_STATUS,
                     type: EventType.places,
                     source: EventSource.requestContent,
                     data: data ?? [
                        PlacesConstants.EventDataKey.Places.REQUEST_TYPE: PlacesConstants.EventDataKey.Places.RequestType.SET_AUTHORIZATION_STATUS,
                        PlacesConstants.EventDataKey.Places.AUTH_STATUS: "always"
                     ])
    }
    
    func getSetAccuracyAuthorizationRequestEvent(_ data: [String: Any]? = nil) -> Event {
        return Event(name: PlacesConstants.EventName.Request.SET_ACCURACY,
                     type: EventType.places,
                     source: EventSource.requestContent,
                     data: data ?? [
                        PlacesConstants.EventDataKey.Places.REQUEST_TYPE: PlacesConstants.EventDataKey.Places.RequestType.SET_ACCURACY,
                        PlacesConstants.EventDataKey.Places.ACCURACY: "full"
                     ])
    }
    
    func getResetEvent() -> Event {
        return Event(name: PlacesConstants.EventName.Request.RESET,
                     type: EventType.places,
                     source: EventSource.requestContent,
                     data: [
                        PlacesConstants.EventDataKey.Places.REQUEST_TYPE: PlacesConstants.EventDataKey.Places.RequestType.RESET
                     ])
    }
    
    // MARK: - Tests
    
    func testOnRegistered() throws {
        // setup
        // onRegistered called in setUpWithError
                
        // verify
        XCTAssertEqual(2, mockRuntime.listeners.count)
        XCTAssertEqual(2, places.nearbyPois.count)
        let placesSharedState = mockRuntime.createdSharedStates[0]
        XCTAssertEqual(6, placesSharedState?.count)
    }

    func testReadyForEventHappy() throws {
        // setup
        mockRuntime.simulateSharedState(for: PlacesConstants.EventDataKey.Configuration.SHARED_STATE_NAME,
                                        data: ([:], .set))
        
        // test
        let result = places.readyForEvent(getConfigSharedStateEvent())
        
        // verify
        XCTAssertTrue(result)
    }
    
    func testReadyForEventConfigSharedStateNotSet() throws {
        // setup
        mockRuntime.simulateSharedState(for: PlacesConstants.EventDataKey.Configuration.SHARED_STATE_NAME,
                                        data: ([:], .pending))
        
        // test
        let result = places.readyForEvent(getConfigSharedStateEvent())
        
        // verify
        XCTAssertFalse(result)
    }
    
    func testHandleShareStateUpdateConfigOptedIn() throws {
        // setup
        prepareConfig(privacy: .optedIn)
        
        // test
        mockRuntime.simulateComingEvents(getConfigSharedStateEvent())
        
        // verify
        XCTAssertEqual(.optedIn, places.privacyStatus)
    }
    
    func testHandleShareStateUpdateConfigOptedOut() throws {
        // setup
        prepareConfig(privacy: .optedOut)
        
        // test
        mockRuntime.simulateComingEvents(getConfigSharedStateEvent())
        
        // verify
        XCTAssertEqual(.optedOut, places.privacyStatus)
        let placesSharedState = mockRuntime.secondSharedState // first shared state is created in onRegistered
        XCTAssertEqual(0, placesSharedState?.count)
    }
    
    func testHandleShareStateUpdateNotConfig() throws {
        // setup
        prepareConfig(privacy: .optedIn)
        
        // test
        mockRuntime.simulateComingEvents(Event(name: "notConfig",
                                               type: EventType.hub,
                                               source: EventSource.sharedState,
                                               data: [PlacesConstants.EventDataKey.SHARED_STATE_OWNER:
                                                      "notConfig"]))
        
        // verify
        // code to update privacy status shouldn't be called, default value is .unknown
        XCTAssertEqual(.unknown, places.privacyStatus)
    }
    
    func testHandleShareStateUpdateNoSharedStateForConfig() throws {
        // test
        mockRuntime.simulateComingEvents(getConfigSharedStateEvent())
        
        // verify
        // code to update privacy status shouldn't be called, default value is .unknown
        XCTAssertEqual(.unknown, places.privacyStatus)
    }
    
    // MARK: - handleGetNearbyPlacesRequest
    
    func testHandleGetNearbyPlaces() throws {
        // setup
        prepareConfig(privacy: .optedIn)
        mockQueryService.returnValue = PlacesQueryServiceResult(pois: [poi, poi2], response: .ok)
        let requestingEvent = getGetNearbyPlacesRequestEvent()
        
        // test
        mockRuntime.simulateComingEvents(requestingEvent)
        
        // verify
        XCTAssertEqual(12.34, mockQueryService.invokedLat)
        XCTAssertEqual(23.45, mockQueryService.invokedLon)
        XCTAssertEqual(7, mockQueryService.invokedCount)
        XCTAssertEqual(2, mockRuntime.dispatchedEvents.count) // one responseEvent, one generic event
        
        // validate response event
        let responseEvent = mockRuntime.firstEvent!
        XCTAssertEqual(requestingEvent.id, responseEvent.responseID)
        XCTAssertEqual(EventType.places, responseEvent.type)
        XCTAssertEqual(EventSource.responseContent, responseEvent.source)
        XCTAssertEqual(PlacesConstants.EventName.Response.GET_NEARBY_PLACES, responseEvent.name)
        let dispatchedData = responseEvent.data!
        let returnedPois = dispatchedData[PlacesConstants.SharedStateKey.NEARBY_POIS] as! [[String: Any]]
        let returnedStatus = PlacesQueryResponseCode(fromRawValue: dispatchedData[PlacesConstants.EventDataKey.Places.RESPONSE_STATUS] as! Int)
        XCTAssertEqual(.ok, returnedStatus)
        XCTAssertEqual(2, returnedPois.count)
        let rpoi1 = returnedPois[0]
        XCTAssertEqual("1234", rpoi1[PlacesConstants.EventDataKey.Places.REGION_ID] as! String)
        let rpoi2 = returnedPois[1]
        XCTAssertEqual("2345", rpoi2[PlacesConstants.EventDataKey.Places.REGION_ID] as! String)
        
        // validate generic event
        let genericEvent = mockRuntime.secondEvent!
        XCTAssertNil(genericEvent.responseID)
        XCTAssertEqual(EventType.places, genericEvent.type)
        XCTAssertEqual(EventSource.responseContent, genericEvent.source)
        XCTAssertEqual(PlacesConstants.EventName.Response.GET_NEARBY_PLACES, genericEvent.name)
        let genericData = genericEvent.data!
        let genericPois = genericData[PlacesConstants.SharedStateKey.NEARBY_POIS] as! [[String: Any]]
        let genericStatus = PlacesQueryResponseCode(fromRawValue: genericData[PlacesConstants.EventDataKey.Places.RESPONSE_STATUS] as! Int)
        XCTAssertEqual(.ok, genericStatus)
        XCTAssertEqual(2, genericPois.count)
        let grpoi1 = genericPois[0]
        XCTAssertEqual("1234", grpoi1[PlacesConstants.EventDataKey.Places.REGION_ID] as! String)
        let grpoi2 = genericPois[1]
        XCTAssertEqual("2345", grpoi2[PlacesConstants.EventDataKey.Places.REGION_ID] as! String)
        
        // validate shared state update
        XCTAssertEqual(2, mockRuntime.createdSharedStates.count)  // first from onRegistered, second as result of this request
    }
    
    func testHandleGetNearbyPlacesNoCountInData() throws {
        // setup
        prepareConfig(privacy: .optedIn)
        mockQueryService.returnValue = PlacesQueryServiceResult(pois: [poi, poi2], response: .ok)
        let requestingEvent = getGetNearbyPlacesRequestEvent([
            PlacesConstants.EventDataKey.Places.LATITUDE: 12.34,
            PlacesConstants.EventDataKey.Places.LONGITUDE: 23.45,
            PlacesConstants.EventDataKey.Places.REQUEST_TYPE: PlacesConstants.EventDataKey.Places.RequestType.GET_NEARBY_PLACES
         ])
        
        // test
        mockRuntime.simulateComingEvents(requestingEvent)
        
        // verify
        XCTAssertEqual(12.34, mockQueryService.invokedLat)
        XCTAssertEqual(23.45, mockQueryService.invokedLon)
        XCTAssertEqual(10, mockQueryService.invokedCount, "Default value for count should be used")
        XCTAssertEqual(2, mockRuntime.dispatchedEvents.count) // one responseEvent, one generic event
        
        // validate response event
        let responseEvent = mockRuntime.firstEvent!
        XCTAssertEqual(requestingEvent.id, responseEvent.responseID)
        XCTAssertEqual(EventType.places, responseEvent.type)
        XCTAssertEqual(EventSource.responseContent, responseEvent.source)
        XCTAssertEqual(PlacesConstants.EventName.Response.GET_NEARBY_PLACES, responseEvent.name)
        let dispatchedData = responseEvent.data!
        let returnedPois = dispatchedData[PlacesConstants.SharedStateKey.NEARBY_POIS] as! [[String: Any]]
        let returnedStatus = PlacesQueryResponseCode(fromRawValue: dispatchedData[PlacesConstants.EventDataKey.Places.RESPONSE_STATUS] as! Int)
        XCTAssertEqual(.ok, returnedStatus)
        XCTAssertEqual(2, returnedPois.count)
        let rpoi1 = returnedPois[0]
        XCTAssertEqual("1234", rpoi1[PlacesConstants.EventDataKey.Places.REGION_ID] as! String)
        let rpoi2 = returnedPois[1]
        XCTAssertEqual("2345", rpoi2[PlacesConstants.EventDataKey.Places.REGION_ID] as! String)
        
        // validate generic event
        let genericEvent = mockRuntime.secondEvent!
        XCTAssertNil(genericEvent.responseID)
        XCTAssertEqual(EventType.places, genericEvent.type)
        XCTAssertEqual(EventSource.responseContent, genericEvent.source)
        XCTAssertEqual(PlacesConstants.EventName.Response.GET_NEARBY_PLACES, genericEvent.name)
        let genericData = genericEvent.data!
        let genericPois = genericData[PlacesConstants.SharedStateKey.NEARBY_POIS] as! [[String: Any]]
        let genericStatus = PlacesQueryResponseCode(fromRawValue: genericData[PlacesConstants.EventDataKey.Places.RESPONSE_STATUS] as! Int)
        XCTAssertEqual(.ok, genericStatus)
        XCTAssertEqual(2, genericPois.count)
        let grpoi1 = genericPois[0]
        XCTAssertEqual("1234", grpoi1[PlacesConstants.EventDataKey.Places.REGION_ID] as! String)
        let grpoi2 = genericPois[1]
        XCTAssertEqual("2345", grpoi2[PlacesConstants.EventDataKey.Places.REGION_ID] as! String)
        
        // validate shared state update
        XCTAssertEqual(2, mockRuntime.createdSharedStates.count)  // first from onRegistered, second as result of this request
    }
    
    func testHandleGetNearbyPlacesNoPoisInResult() throws {
        // setup
        prepareConfig(privacy: .optedIn)
        mockQueryService.returnValue = PlacesQueryServiceResult(pois: nil, response: .ok)
        let requestingEvent = getGetNearbyPlacesRequestEvent()
        
        // test
        mockRuntime.simulateComingEvents(requestingEvent)
        
        // verify
        XCTAssertEqual(12.34, mockQueryService.invokedLat)
        XCTAssertEqual(23.45, mockQueryService.invokedLon)
        XCTAssertEqual(7, mockQueryService.invokedCount)
        XCTAssertEqual(2, mockRuntime.dispatchedEvents.count) // one responseEvent, one generic event
        
        // validate response event
        let responseEvent = mockRuntime.firstEvent!
        XCTAssertEqual(requestingEvent.id, responseEvent.responseID)
        XCTAssertEqual(EventType.places, responseEvent.type)
        XCTAssertEqual(EventSource.responseContent, responseEvent.source)
        XCTAssertEqual(PlacesConstants.EventName.Response.GET_NEARBY_PLACES, responseEvent.name)
        let dispatchedData = responseEvent.data!
        let returnedPois = dispatchedData[PlacesConstants.SharedStateKey.NEARBY_POIS] as! [[String: Any]]
        let returnedStatus = PlacesQueryResponseCode(fromRawValue: dispatchedData[PlacesConstants.EventDataKey.Places.RESPONSE_STATUS] as! Int)
        XCTAssertEqual(.ok, returnedStatus)
        XCTAssertEqual(0, returnedPois.count)
                
        // validate shared state update
        XCTAssertEqual(2, mockRuntime.createdSharedStates.count)  // first from onRegistered, second as result of this request
    }
    
    func testHandleGetNearbyPlacesPrivacyOptedOut() throws {
        // setup
        prepareConfig(privacy: .optedOut)
        places.privacyStatus = .optedOut
        let requestingEvent = getGetNearbyPlacesRequestEvent()
        
        // test
        mockRuntime.simulateComingEvents(requestingEvent)
        
        // verify
        XCTAssertFalse(mockQueryService.getNearbyPlacesWasCalled)
        XCTAssertEqual(1, mockRuntime.dispatchedEvents.count) // one responseEvent
        let responseEvent = mockRuntime.firstEvent!
        XCTAssertEqual(requestingEvent.id, responseEvent.responseID)
        XCTAssertEqual(EventType.places, responseEvent.type)
        XCTAssertEqual(EventSource.responseContent, responseEvent.source)
        XCTAssertEqual(PlacesConstants.EventName.Response.GET_NEARBY_PLACES, responseEvent.name)
        let dispatchedData = responseEvent.data!
        XCTAssertEqual(1, dispatchedData.count)
        XCTAssertEqual(.privacyOptedOut, dispatchedData[PlacesConstants.EventDataKey.Places.RESPONSE_STATUS] as? PlacesQueryResponseCode)
    }
    
    func testHandleGetNearbyPlacesNoPlacesConfig() throws {
        // setup
        prepareConfigMissingPlaces()
        let requestingEvent = getGetNearbyPlacesRequestEvent()
        
        // test
        mockRuntime.simulateComingEvents(requestingEvent)
        
        // verify
        XCTAssertFalse(mockQueryService.getNearbyPlacesWasCalled)
        XCTAssertEqual(1, mockRuntime.dispatchedEvents.count) // one responseEvent
        let responseEvent = mockRuntime.firstEvent!
        XCTAssertEqual(requestingEvent.id, responseEvent.responseID)
        XCTAssertEqual(EventType.places, responseEvent.type)
        XCTAssertEqual(EventSource.responseContent, responseEvent.source)
        XCTAssertEqual(PlacesConstants.EventName.Response.GET_NEARBY_PLACES, responseEvent.name)
        let dispatchedData = responseEvent.data!
        XCTAssertEqual(1, dispatchedData.count)
        XCTAssertEqual(.configurationError, dispatchedData[PlacesConstants.EventDataKey.Places.RESPONSE_STATUS] as? PlacesQueryResponseCode)
    }
    
    func testHandleGetNearbyPlacesPlacesConfigInvalid() throws {
        // setup
        prepareConfigInvalidPlaces()
        let requestingEvent = getGetNearbyPlacesRequestEvent()
        
        // test
        mockRuntime.simulateComingEvents(requestingEvent)
        
        // verify
        XCTAssertFalse(mockQueryService.getNearbyPlacesWasCalled)
        XCTAssertEqual(1, mockRuntime.dispatchedEvents.count) // one responseEvent
        let responseEvent = mockRuntime.firstEvent!
        XCTAssertEqual(requestingEvent.id, responseEvent.responseID)
        XCTAssertEqual(EventType.places, responseEvent.type)
        XCTAssertEqual(EventSource.responseContent, responseEvent.source)
        XCTAssertEqual(PlacesConstants.EventName.Response.GET_NEARBY_PLACES, responseEvent.name)
        let dispatchedData = responseEvent.data!
        XCTAssertEqual(1, dispatchedData.count)
        XCTAssertEqual(.configurationError, dispatchedData[PlacesConstants.EventDataKey.Places.RESPONSE_STATUS] as? PlacesQueryResponseCode)
    }
    
    func testHandleGetNearbyPlacesNoLatitudeInEventData() throws {
        // setup
        prepareConfig(privacy: .optedIn)
        let requestingEvent = getGetNearbyPlacesRequestEvent([
            PlacesConstants.EventDataKey.Places.LONGITUDE: 23.45,
            PlacesConstants.EventDataKey.Places.COUNT: 7,
            PlacesConstants.EventDataKey.Places.REQUEST_TYPE: PlacesConstants.EventDataKey.Places.RequestType.GET_NEARBY_PLACES
         ])
        
        // test
        mockRuntime.simulateComingEvents(requestingEvent)
        
        // verify
        XCTAssertFalse(mockQueryService.getNearbyPlacesWasCalled)
        XCTAssertEqual(1, mockRuntime.dispatchedEvents.count) // one responseEvent
        let responseEvent = mockRuntime.firstEvent!
        XCTAssertEqual(requestingEvent.id, responseEvent.responseID)
        XCTAssertEqual(EventType.places, responseEvent.type)
        XCTAssertEqual(EventSource.responseContent, responseEvent.source)
        XCTAssertEqual(PlacesConstants.EventName.Response.GET_NEARBY_PLACES, responseEvent.name)
        let dispatchedData = responseEvent.data!
        XCTAssertEqual(1, dispatchedData.count)
        XCTAssertEqual(.invalidLatLongError, dispatchedData[PlacesConstants.EventDataKey.Places.RESPONSE_STATUS] as? PlacesQueryResponseCode)
    }
    
    func testHandleGetNearbyPlacesNoLongitudeInEventData() throws {
        // setup
        prepareConfig(privacy: .optedIn)
        let requestingEvent = getGetNearbyPlacesRequestEvent([
            PlacesConstants.EventDataKey.Places.LATITUDE: 12.34,
            PlacesConstants.EventDataKey.Places.COUNT: 7,
            PlacesConstants.EventDataKey.Places.REQUEST_TYPE: PlacesConstants.EventDataKey.Places.RequestType.GET_NEARBY_PLACES
         ])
        
        // test
        mockRuntime.simulateComingEvents(requestingEvent)
        
        // verify
        XCTAssertFalse(mockQueryService.getNearbyPlacesWasCalled)
        XCTAssertEqual(1, mockRuntime.dispatchedEvents.count) // one responseEvent
        let responseEvent = mockRuntime.firstEvent!
        XCTAssertEqual(requestingEvent.id, responseEvent.responseID)
        XCTAssertEqual(EventType.places, responseEvent.type)
        XCTAssertEqual(EventSource.responseContent, responseEvent.source)
        XCTAssertEqual(PlacesConstants.EventName.Response.GET_NEARBY_PLACES, responseEvent.name)
        let dispatchedData = responseEvent.data!
        XCTAssertEqual(1, dispatchedData.count)
        XCTAssertEqual(.invalidLatLongError, dispatchedData[PlacesConstants.EventDataKey.Places.RESPONSE_STATUS] as? PlacesQueryResponseCode)
    }
    
    func testHandleGetNearbyPlacesResponseIsError() throws {
        // setup
        prepareConfig(privacy: .optedIn)
        mockQueryService.returnValue = PlacesQueryServiceResult(pois: [], response: .unknownError)
        let requestingEvent = getGetNearbyPlacesRequestEvent()
        
        // test
        mockRuntime.simulateComingEvents(requestingEvent)
        
        // verify
        XCTAssertEqual(12.34, mockQueryService.invokedLat)
        XCTAssertEqual(23.45, mockQueryService.invokedLon)
        XCTAssertEqual(7, mockQueryService.invokedCount)
        XCTAssertEqual(2, mockRuntime.dispatchedEvents.count) // one responseEvent, one generic event
        
        // validate response event
        let responseEvent = mockRuntime.firstEvent!
        XCTAssertEqual(requestingEvent.id, responseEvent.responseID)
        XCTAssertEqual(EventType.places, responseEvent.type)
        XCTAssertEqual(EventSource.responseContent, responseEvent.source)
        XCTAssertEqual(PlacesConstants.EventName.Response.GET_NEARBY_PLACES, responseEvent.name)
        let dispatchedData = responseEvent.data!
        let returnedPois = dispatchedData[PlacesConstants.SharedStateKey.NEARBY_POIS] as! [[String: Any]]
        let returnedStatus = PlacesQueryResponseCode(fromRawValue: dispatchedData[PlacesConstants.EventDataKey.Places.RESPONSE_STATUS] as! Int)
        XCTAssertEqual(.unknownError, returnedStatus)
        XCTAssertEqual(0, returnedPois.count)
        
        // validate generic event
        let genericEvent = mockRuntime.secondEvent!
        XCTAssertNil(genericEvent.responseID)
        XCTAssertEqual(EventType.places, genericEvent.type)
        XCTAssertEqual(EventSource.responseContent, genericEvent.source)
        XCTAssertEqual(PlacesConstants.EventName.Response.GET_NEARBY_PLACES, genericEvent.name)
        let genericData = genericEvent.data!
        let genericPois = genericData[PlacesConstants.SharedStateKey.NEARBY_POIS] as! [[String: Any]]
        let genericStatus = PlacesQueryResponseCode(fromRawValue: genericData[PlacesConstants.EventDataKey.Places.RESPONSE_STATUS] as! Int)
        XCTAssertEqual(.unknownError, genericStatus)
        XCTAssertEqual(0, genericPois.count)
                
        // validate shared state update
        XCTAssertEqual(1, mockRuntime.createdSharedStates.count)  // first from onRegistered, no update as a result of this request
    }
    
    func testHandleGetNearbyPlacesNoConfigSharedState() throws {
        // setup
        let requestingEvent = getGetNearbyPlacesRequestEvent()
        
        // test
        mockRuntime.simulateComingEvents(requestingEvent)
        
        // verify
        XCTAssertFalse(mockQueryService.getNearbyPlacesWasCalled)
        XCTAssertEqual(1, mockRuntime.dispatchedEvents.count) // one responseEvent
        let responseEvent = mockRuntime.firstEvent!
        XCTAssertEqual(requestingEvent.id, responseEvent.responseID)
        XCTAssertEqual(EventType.places, responseEvent.type)
        XCTAssertEqual(EventSource.responseContent, responseEvent.source)
        XCTAssertEqual(PlacesConstants.EventName.Response.GET_NEARBY_PLACES, responseEvent.name)
        let dispatchedData = responseEvent.data!
        XCTAssertEqual(1, dispatchedData.count)
        XCTAssertEqual(.configurationError, dispatchedData[PlacesConstants.EventDataKey.Places.RESPONSE_STATUS] as? PlacesQueryResponseCode)
    }
    
    // MARK: - handleProcessRegionEventRequest
    
    func testHandleProcessRegionEventRequestEntry() throws {
        // setup
        prepareConfig(privacy: .optedIn)
        let requestingEvent = getProcessRegionEvent()
        
        // test
        mockRuntime.simulateComingEvents(requestingEvent)
        
        // verify
        XCTAssertEqual(2, mockRuntime.dispatchedEvents.count)
        
        // validate places region response event
        let responseEvent = mockRuntime.firstEvent!
        XCTAssertEqual(EventType.places, responseEvent.type)
        XCTAssertEqual(EventSource.responseContent, responseEvent.source)
        XCTAssertEqual(PlacesConstants.EventName.Response.PROCESS_REGION_EVENT, responseEvent.name)
        let dispatchedData = responseEvent.data!
        
        let regionEventType = PlacesRegionEvent.fromString(dispatchedData[PlacesConstants.EventDataKey.Places.REGION_EVENT_TYPE] as! String)
        XCTAssertEqual(.entry, regionEventType)
        
        let triggeringRegion = dispatchedData[PlacesConstants.EventDataKey.Places.TRIGGERING_REGION] as! [String: Any]
        XCTAssertEqual("1234", triggeringRegion[PlacesConstants.EventDataKey.Places.REGION_ID] as? String)
        XCTAssertEqual("myplace", triggeringRegion[PlacesConstants.EventDataKey.Places.REGION_NAME] as? String)
        XCTAssertEqual(12.34, triggeringRegion[PlacesConstants.EventDataKey.Places.LATITUDE] as? Double)
        XCTAssertEqual(23.45, triggeringRegion[PlacesConstants.EventDataKey.Places.LONGITUDE] as? Double)
        XCTAssertEqual(500, triggeringRegion[PlacesConstants.EventDataKey.Places.RADIUS] as? Int)
        XCTAssertEqual(25, triggeringRegion[PlacesConstants.EventDataKey.Places.WEIGHT] as? Int)
        XCTAssertEqual("mylib", triggeringRegion[PlacesConstants.EventDataKey.Places.LIBRARY_ID] as? String)
        XCTAssertTrue(triggeringRegion[PlacesConstants.EventDataKey.Places.USER_IS_WITHIN] as? Bool ?? false)
        let triggeringMetaData = triggeringRegion[PlacesConstants.EventDataKey.Places.REGION_META_DATA] as! [String: Any]
        XCTAssertEqual("value1", triggeringMetaData["key1"] as? String)
        
        // validate state updates
        XCTAssertEqual("1234", places.currentPoi?.identifier)
        XCTAssertEqual("1234", places.lastEnteredPoi?.identifier)
        
        // validate shared state update
        XCTAssertEqual(2, mockRuntime.createdSharedStates.count)  // first from onRegistered, second as result of this request
        let sharedState = mockRuntime.secondSharedState
        let sharedLastEnteredPoi = sharedState?[PlacesConstants.SharedStateKey.LAST_ENTERED_POI] as? [String: Any]
        XCTAssertEqual("1234", sharedLastEnteredPoi?[PlacesConstants.EventDataKey.Places.REGION_ID] as? String)
        
        // validate experience edge request event
        let edgeRequestEvent = mockRuntime.secondEvent!
        XCTAssertEqual(EventType.edge, edgeRequestEvent.type)
        XCTAssertEqual(EventSource.requestContent, edgeRequestEvent.source)
        XCTAssertEqual(PlacesConstants.EventName.Request.LOCATION_TRACKING, edgeRequestEvent.name)
        
        let dispatchedEdgeEventData = edgeRequestEvent.data!
        let xdm = dispatchedEdgeEventData[PlacesConstants.XDM.Key.XDM] as! [String: Any]
        XCTAssertEqual("location.entry", xdm[PlacesConstants.XDM.Key.EVENT_TYPE] as! String)
        
        let placesContext = xdm[PlacesConstants.XDM.Key.PLACE_CONTEXT] as! [String: Any]
        let poiInteraction = placesContext[PlacesConstants.XDM.Key.POI_INTERACTION] as! [String: Any]
        
        let poiDetail = poiInteraction[PlacesConstants.XDM.Key.POI_DETAIL] as! [String: Any]
        XCTAssertEqual("1234", poiDetail[PlacesConstants.XDM.Key.POI_ID] as! String)
        XCTAssertEqual("myplace", poiDetail[PlacesConstants.XDM.Key.NAME] as! String)
        
        let metadata = poiDetail[PlacesConstants.XDM.Key.METADATA] as! [String: Any]
        let metadataList = metadata[PlacesConstants.XDM.Key.LIST] as! [[String: Any]]
        XCTAssertEqual(1, metadataList.count)
        XCTAssertEqual("key1", metadataList[0][PlacesConstants.XDM.Key.KEY] as! String)
        XCTAssertEqual("value1", metadataList[0][PlacesConstants.XDM.Key.VALUE] as! String)
        
        let geoInteractionDetails = poiDetail[PlacesConstants.XDM.Key.GEO_INTERACTION_DETAILS] as! [String: Any]
        let geoShape = geoInteractionDetails[PlacesConstants.XDM.Key.SCHEMA] as! [String: Any]
        let circle = geoShape[PlacesConstants.XDM.Key.CIRCLE] as! [String: Any]
        let circleSchema = circle[PlacesConstants.XDM.Key.SCHEMA] as! [String: Any]
        XCTAssertEqual(500, circleSchema[PlacesConstants.XDM.Key.RADIUS] as! Int)
        
        let coordinates = circleSchema[PlacesConstants.XDM.Key.COORDINATES] as! [String: Any]
        let coordinatesSchema = coordinates[PlacesConstants.XDM.Key.SCHEMA] as! [String: Any]
        XCTAssertEqual(12.34, coordinatesSchema[PlacesConstants.XDM.Key.LATITUDE] as! Double)
        XCTAssertEqual(23.45, coordinatesSchema[PlacesConstants.XDM.Key.LONGITUDE] as! Double)
        
        let poiEntries = poiInteraction[PlacesConstants.XDM.Key.POIENTRIES] as! [String: Any]
        XCTAssertEqual("1234", poiEntries[PlacesConstants.XDM.Key.ID] as! String)
        XCTAssertEqual(1, poiEntries[PlacesConstants.XDM.Key.VALUE] as! Int)

        let meta = dispatchedEdgeEventData[PlacesConstants.XDM.Key.META] as! [String: Any]
        let collect = meta[PlacesConstants.XDM.Key.COLLECT] as! [String: Any]
        XCTAssertEqual("datasetId", collect[PlacesConstants.XDM.Key.DATASET_ID] as! String)

        XCTAssertEqual(["xdm.eventType"], edgeRequestEvent.mask)
    }
    
    func testHandleProcessRegionEventRequestExit() throws {
        // setup
        prepareConfig(privacy: .optedIn)
        let requestingEvent = getProcessRegionEvent(regionEventType: PlacesRegionEvent.exit.stringValue)
        
        // test
        mockRuntime.simulateComingEvents(requestingEvent)
        
        // verify
        XCTAssertEqual(2, mockRuntime.dispatchedEvents.count)
        
        // validate places region response event
        let responseEvent = mockRuntime.firstEvent!
        XCTAssertEqual(EventType.places, responseEvent.type)
        XCTAssertEqual(EventSource.responseContent, responseEvent.source)
        XCTAssertEqual(PlacesConstants.EventName.Response.PROCESS_REGION_EVENT, responseEvent.name)
        let dispatchedData = responseEvent.data!
        
        let regionEventType = PlacesRegionEvent.fromString(dispatchedData[PlacesConstants.EventDataKey.Places.REGION_EVENT_TYPE] as! String)
        XCTAssertEqual(.exit, regionEventType)
        
        let triggeringRegion = dispatchedData[PlacesConstants.EventDataKey.Places.TRIGGERING_REGION] as! [String: Any]
        XCTAssertEqual("1234", triggeringRegion[PlacesConstants.EventDataKey.Places.REGION_ID] as? String)
        XCTAssertEqual("myplace", triggeringRegion[PlacesConstants.EventDataKey.Places.REGION_NAME] as? String)
        XCTAssertEqual(12.34, triggeringRegion[PlacesConstants.EventDataKey.Places.LATITUDE] as? Double)
        XCTAssertEqual(23.45, triggeringRegion[PlacesConstants.EventDataKey.Places.LONGITUDE] as? Double)
        XCTAssertEqual(500, triggeringRegion[PlacesConstants.EventDataKey.Places.RADIUS] as? Int)
        XCTAssertEqual(25, triggeringRegion[PlacesConstants.EventDataKey.Places.WEIGHT] as? Int)
        XCTAssertEqual("mylib", triggeringRegion[PlacesConstants.EventDataKey.Places.LIBRARY_ID] as? String)
        XCTAssertTrue(triggeringRegion[PlacesConstants.EventDataKey.Places.USER_IS_WITHIN] as? Bool ?? false)
        let triggeringMetaData = triggeringRegion[PlacesConstants.EventDataKey.Places.REGION_META_DATA] as! [String: Any]
        XCTAssertEqual("value1", triggeringMetaData["key1"] as? String)
        
        // validate state updates
        XCTAssertNil(places.currentPoi)
        XCTAssertEqual("1234", places.lastExitedPoi?.identifier)
        
        // validate shared state update
        XCTAssertEqual(2, mockRuntime.createdSharedStates.count)  // first from onRegistered, second as result of this request
        let sharedState = mockRuntime.secondSharedState
        let sharedLastEnteredPoi = sharedState?[PlacesConstants.SharedStateKey.LAST_ENTERED_POI] as? [String: Any]
        XCTAssertEqual("1234", sharedLastEnteredPoi?[PlacesConstants.EventDataKey.Places.REGION_ID] as? String)
        
        // validate experience edge request event
        let edgeRequestEvent = mockRuntime.secondEvent!
        XCTAssertEqual(EventType.edge, edgeRequestEvent.type)
        XCTAssertEqual(EventSource.requestContent, edgeRequestEvent.source)
        XCTAssertEqual(PlacesConstants.EventName.Request.LOCATION_TRACKING, edgeRequestEvent.name)
        
        let dispatchedEdgeEventData = edgeRequestEvent.data!
        let xdm = dispatchedEdgeEventData[PlacesConstants.XDM.Key.XDM] as! [String: Any]
        XCTAssertEqual("location.exit", xdm[PlacesConstants.XDM.Key.EVENT_TYPE] as! String)
        
        let placesContext = xdm[PlacesConstants.XDM.Key.PLACE_CONTEXT] as! [String: Any]
        let poiInteraction = placesContext[PlacesConstants.XDM.Key.POI_INTERACTION] as! [String: Any]
        
        let poiDetail = poiInteraction[PlacesConstants.XDM.Key.POI_DETAIL] as! [String: Any]
        XCTAssertEqual("1234", poiDetail[PlacesConstants.XDM.Key.POI_ID] as! String)
        XCTAssertEqual("myplace", poiDetail[PlacesConstants.XDM.Key.NAME] as! String)
        
        let metadata = poiDetail[PlacesConstants.XDM.Key.METADATA] as! [String: Any]
        let metadataList = metadata[PlacesConstants.XDM.Key.LIST] as! [[String: Any]]
        XCTAssertEqual(1, metadataList.count)
        XCTAssertEqual("key1", metadataList[0][PlacesConstants.XDM.Key.KEY] as! String)
        XCTAssertEqual("value1", metadataList[0][PlacesConstants.XDM.Key.VALUE] as! String)
        
        let geoInteractionDetails = poiDetail[PlacesConstants.XDM.Key.GEO_INTERACTION_DETAILS] as! [String: Any]
        let geoShape = geoInteractionDetails[PlacesConstants.XDM.Key.SCHEMA] as! [String: Any]
        let circle = geoShape[PlacesConstants.XDM.Key.CIRCLE] as! [String: Any]
        let circleSchema = circle[PlacesConstants.XDM.Key.SCHEMA] as! [String: Any]
        XCTAssertEqual(500, circleSchema[PlacesConstants.XDM.Key.RADIUS] as! Int)
        
        let coordinates = circleSchema[PlacesConstants.XDM.Key.COORDINATES] as! [String: Any]
        let coordinatesSchema = coordinates[PlacesConstants.XDM.Key.SCHEMA] as! [String: Any]
        XCTAssertEqual(12.34, coordinatesSchema[PlacesConstants.XDM.Key.LATITUDE] as! Double)
        XCTAssertEqual(23.45, coordinatesSchema[PlacesConstants.XDM.Key.LONGITUDE] as! Double)
        
        let poiExits = poiInteraction[PlacesConstants.XDM.Key.POIEXITS] as! [String: Any]
        XCTAssertEqual("1234", poiExits[PlacesConstants.XDM.Key.ID] as! String)
        XCTAssertEqual(1, poiExits[PlacesConstants.XDM.Key.VALUE] as! Int)

        let meta = dispatchedEdgeEventData[PlacesConstants.XDM.Key.META] as! [String: Any]
        let collect = meta[PlacesConstants.XDM.Key.COLLECT] as! [String: Any]
        XCTAssertEqual("datasetId", collect[PlacesConstants.XDM.Key.DATASET_ID] as! String)

        XCTAssertEqual(["xdm.eventType"], edgeRequestEvent.mask)
    }
    
    func testHandleProcessRegionEventRequestPrivacyOptedOut() throws {
        // setup
        prepareConfig(privacy: .optedOut)
        places.privacyStatus = .optedOut
        let requestingEvent = getProcessRegionEvent()
        
        // test
        mockRuntime.simulateComingEvents(requestingEvent)
        
        // verify
        XCTAssertEqual(0, mockRuntime.dispatchedEvents.count)
    }
    
    func testHandleProcessRegionEventRequestPlacesConfigMissing() throws {
        // setup
        prepareConfigMissingPlaces()
        let requestingEvent = getProcessRegionEvent()
        
        // test
        mockRuntime.simulateComingEvents(requestingEvent)
        
        // verify
        XCTAssertEqual(0, mockRuntime.dispatchedEvents.count)
    }
    
    func testHandleProcessRegionEventRequestInvalidPlacesConfig() throws {
        // setup
        prepareConfigInvalidPlaces()
        let requestingEvent = getProcessRegionEvent()
        
        // test
        mockRuntime.simulateComingEvents(requestingEvent)
        
        // verify
        XCTAssertEqual(0, mockRuntime.dispatchedEvents.count)
    }
    
    func testHandleProcessRegionEventRequestMissingRegionId() throws {
        // setup
        prepareConfig(privacy: .optedIn)
        let requestingEvent = getProcessRegionEvent([
            PlacesConstants.EventDataKey.Places.REGION_EVENT_TYPE: PlacesRegionEvent.entry.stringValue,
            PlacesConstants.EventDataKey.Places.REQUEST_TYPE: PlacesConstants.EventDataKey.Places.RequestType.PROCESS_REGION_EVENT
         ])
        
        // test
        mockRuntime.simulateComingEvents(requestingEvent)
        
        // verify
        XCTAssertEqual(0, mockRuntime.dispatchedEvents.count)
    }
    
    func testHandleProcessRegionEventRequestMissingRegionEventType() throws {
        // setup
        prepareConfig(privacy: .optedIn)
        let requestingEvent = getProcessRegionEvent([
            PlacesConstants.EventDataKey.Places.REGION_ID: "1234",
            PlacesConstants.EventDataKey.Places.REQUEST_TYPE: PlacesConstants.EventDataKey.Places.RequestType.PROCESS_REGION_EVENT
         ])
        
        // test
        mockRuntime.simulateComingEvents(requestingEvent)
        
        // verify
        XCTAssertEqual(0, mockRuntime.dispatchedEvents.count)
    }
    
    func testHandleProcessRegionEventRequestTriggeringPoiNotInNearbyPois() throws {
        // setup
        prepareConfig(privacy: .optedIn)
        places.nearbyPois.removeAll()
        let requestingEvent = getProcessRegionEvent()
        
        // test
        mockRuntime.simulateComingEvents(requestingEvent)
        
        // verify
        XCTAssertEqual(0, mockRuntime.dispatchedEvents.count)
    }
    
    func testHandleProcessRegionEventRequestDatasetNil() throws {
        // setup
        prepareConfigWithDataset(datasetId: nil)
        let requestingEvent = getProcessRegionEvent()
        
        // test
        mockRuntime.simulateComingEvents(requestingEvent)
        
        // verify only places response event is dispatched but not edge event
        XCTAssertEqual(1, mockRuntime.dispatchedEvents.count)
        let responseEvent = mockRuntime.firstEvent!
        XCTAssertEqual(EventType.places, responseEvent.type)
        XCTAssertEqual(EventSource.responseContent, responseEvent.source)
    }
    
    func testHandleProcessRegionEventRequestDatasetEmpty() throws {
        // setup
        prepareConfigWithDataset(datasetId: "")
        let requestingEvent = getProcessRegionEvent()
        
        // test
        mockRuntime.simulateComingEvents(requestingEvent)
        
        // verify only places response event is dispatched but not edge event
        XCTAssertEqual(1, mockRuntime.dispatchedEvents.count)
        let responseEvent = mockRuntime.firstEvent!
        XCTAssertEqual(EventType.places, responseEvent.type)
        XCTAssertEqual(EventSource.responseContent, responseEvent.source)
    }
    
    func testHandleProcessRegionEventRequestDatasetMissing() throws {
        // setup
        prepareConfigMissingDataset()
        let requestingEvent = getProcessRegionEvent()
        
        // test
        mockRuntime.simulateComingEvents(requestingEvent)
        
        // verify only places response event is dispatched but not edge event
        XCTAssertEqual(1, mockRuntime.dispatchedEvents.count)
        let responseEvent = mockRuntime.firstEvent!
        XCTAssertEqual(EventType.places, responseEvent.type)
        XCTAssertEqual(EventSource.responseContent, responseEvent.source)
    }
    
    // MARK: - getUserWithinPlaces
    
    func testGetUserWithinPlaces() throws {
        // setup
        prepareConfig(privacy: .optedIn)
        let requestingEvent = getUserWithinPlacesRequestEvent()
        
        // test
        mockRuntime.simulateComingEvents(requestingEvent)
        
        // verify
        XCTAssertEqual(2, mockRuntime.dispatchedEvents.count) // response event and generic event
        
        let responseEvent = mockRuntime.firstEvent!
        XCTAssertEqual(requestingEvent.id, responseEvent.responseID)
        XCTAssertEqual(EventType.places, responseEvent.type)
        XCTAssertEqual(EventSource.responseContent, responseEvent.source)
        XCTAssertEqual(PlacesConstants.EventName.Response.GET_USER_WITHIN_PLACES, responseEvent.name)
        let dispatchedData = responseEvent.data!
        let returnedPois = dispatchedData[PlacesConstants.SharedStateKey.USER_WITHIN_POIS] as! [[String: Any]]
        XCTAssertEqual(1, returnedPois.count)
        let rpoi1 = returnedPois[0]
        XCTAssertEqual("1234", rpoi1[PlacesConstants.EventDataKey.Places.REGION_ID] as! String)
                
        // validate generic event
        let genericEvent = mockRuntime.secondEvent!
        XCTAssertNil(genericEvent.responseID)
        XCTAssertEqual(EventType.places, genericEvent.type)
        XCTAssertEqual(EventSource.responseContent, genericEvent.source)
        XCTAssertEqual(PlacesConstants.EventName.Response.GET_USER_WITHIN_PLACES, genericEvent.name)
        let genericData = genericEvent.data!
        let genericPois = genericData[PlacesConstants.SharedStateKey.USER_WITHIN_POIS] as! [[String: Any]]
        XCTAssertEqual(1, genericPois.count)
        let grpoi1 = genericPois[0]
        XCTAssertEqual("1234", grpoi1[PlacesConstants.EventDataKey.Places.REGION_ID] as! String)
    }
    
    func testGetUserWithinPlacesUserWithinPoisIsEmpty() throws {
        // setup
        prepareConfig(privacy: .optedIn)
        places.userWithinPois.removeAll()
        let requestingEvent = getUserWithinPlacesRequestEvent()
        
        // test
        mockRuntime.simulateComingEvents(requestingEvent)
        
        // verify
        XCTAssertEqual(2, mockRuntime.dispatchedEvents.count) // response event and generic event
        
        let responseEvent = mockRuntime.firstEvent!
        XCTAssertEqual(requestingEvent.id, responseEvent.responseID)
        XCTAssertEqual(EventType.places, responseEvent.type)
        XCTAssertEqual(EventSource.responseContent, responseEvent.source)
        XCTAssertEqual(PlacesConstants.EventName.Response.GET_USER_WITHIN_PLACES, responseEvent.name)
        let dispatchedData = responseEvent.data!
        let returnedPois = dispatchedData[PlacesConstants.SharedStateKey.USER_WITHIN_POIS] as! [[String: Any]]
        XCTAssertEqual(0, returnedPois.count)
                
        // validate generic event
        let genericEvent = mockRuntime.secondEvent!
        XCTAssertNil(genericEvent.responseID)
        XCTAssertEqual(EventType.places, genericEvent.type)
        XCTAssertEqual(EventSource.responseContent, genericEvent.source)
        XCTAssertEqual(PlacesConstants.EventName.Response.GET_USER_WITHIN_PLACES, genericEvent.name)
        let genericData = genericEvent.data!
        let genericPois = genericData[PlacesConstants.SharedStateKey.USER_WITHIN_POIS] as! [[String: Any]]
        XCTAssertEqual(0, genericPois.count)
    }
    
    func testGetLastKnownLocation() throws {
        // setup
        prepareConfig(privacy: .optedIn)
        let requestingEvent = getLastKnownLocationRequestEvent()
        
        // test
        mockRuntime.simulateComingEvents(requestingEvent)
        
        // verify
        XCTAssertEqual(2, mockRuntime.dispatchedEvents.count)
        
        let responseEvent = mockRuntime.firstEvent!
        XCTAssertEqual(requestingEvent.id, responseEvent.responseID)
        XCTAssertEqual(EventType.places, responseEvent.type)
        XCTAssertEqual(EventSource.responseContent, responseEvent.source)
        XCTAssertEqual(PlacesConstants.EventName.Response.GET_LAST_KNOWN_LOCATION, responseEvent.name)
        let dispatchedData = responseEvent.data!
        XCTAssertEqual(places.lastKnownCoordinate.latitude, dispatchedData[PlacesConstants.EventDataKey.Places.LATITUDE] as? Double)
        XCTAssertEqual(places.lastKnownCoordinate.longitude, dispatchedData[PlacesConstants.EventDataKey.Places.LONGITUDE] as? Double)
        
        // validate generic event
        let genericEvent = mockRuntime.secondEvent!
        XCTAssertNil(genericEvent.responseID)
        XCTAssertEqual(EventType.places, genericEvent.type)
        XCTAssertEqual(EventSource.responseContent, genericEvent.source)
        XCTAssertEqual(PlacesConstants.EventName.Response.GET_LAST_KNOWN_LOCATION, genericEvent.name)
        let genericData = genericEvent.data!
        XCTAssertEqual(places.lastKnownCoordinate.latitude, genericData[PlacesConstants.EventDataKey.Places.LATITUDE] as? Double)
        XCTAssertEqual(places.lastKnownCoordinate.longitude, genericData[PlacesConstants.EventDataKey.Places.LONGITUDE] as? Double)
    }
    
    func testSetAccuracyAuthorization() throws {
        guard #available(iOS 14, *) else {
            return
        }
        
        // setup
        prepareConfig(privacy: .optedIn)
        let requestingEvent = getSetAccuracyAuthorizationRequestEvent()
        XCTAssertNil(places.accuracy)
        
        // test
        mockRuntime.simulateComingEvents(requestingEvent)
        
        // verify
        XCTAssertEqual(0, mockRuntime.dispatchedEvents.count)
        XCTAssertEqual(.fullAccuracy, places.accuracy)
        XCTAssertEqual(2, mockRuntime.createdSharedStates.count)  // first from onRegistered, second as result of this event
        let sharedState = mockRuntime.secondSharedState
        XCTAssertEqual("full", sharedState?[PlacesConstants.SharedStateKey.ACCURACY] as? String)
    }
    
    func testSetAccuracyAuthorizationNoAccuracyInEventData() throws {
        guard #available(iOS 14, *) else {
            return
        }
        
        // setup
        prepareConfig(privacy: .optedIn)
        let requestingEvent = getSetAccuracyAuthorizationRequestEvent([
            PlacesConstants.EventDataKey.Places.REQUEST_TYPE: PlacesConstants.EventDataKey.Places.RequestType.SET_ACCURACY
        ])
        XCTAssertNil(places.accuracy)
        
        // test
        mockRuntime.simulateComingEvents(requestingEvent)
        
        // verify
        XCTAssertEqual(0, mockRuntime.dispatchedEvents.count)
        XCTAssertNil(places.accuracy)
        XCTAssertEqual(1, mockRuntime.createdSharedStates.count)  // only from onRegistered
    }
    
    func testSetAuthorizationStatus() throws {
        // setup
        prepareConfig(privacy: .optedIn)
        let requestingEvent = getSetAuthorizationStatusRequestEvent()
        XCTAssertEqual(.notDetermined, places.authStatus)
        
        // test
        mockRuntime.simulateComingEvents(requestingEvent)
        
        // verify
        XCTAssertEqual(0, mockRuntime.dispatchedEvents.count)
        XCTAssertEqual(.authorizedAlways, places.authStatus)
        XCTAssertEqual(2, mockRuntime.createdSharedStates.count)  // first from onRegistered, second as result of this event
        let sharedState = mockRuntime.secondSharedState
        XCTAssertEqual("always", sharedState?[PlacesConstants.SharedStateKey.AUTH_STATUS] as? String)
    }
    
    func testSetAuthorizationStatusNoStatusInEventData() throws {
        // setup
        prepareConfig(privacy: .optedIn)
        let requestingEvent = getSetAuthorizationStatusRequestEvent([
            PlacesConstants.EventDataKey.Places.REQUEST_TYPE: PlacesConstants.EventDataKey.Places.RequestType.SET_AUTHORIZATION_STATUS
        ])        
        XCTAssertEqual(.notDetermined, places.authStatus)
        
        // test
        mockRuntime.simulateComingEvents(requestingEvent)
        
        // verify
        XCTAssertEqual(0, mockRuntime.dispatchedEvents.count)
        XCTAssertEqual(.notDetermined, places.authStatus)
        XCTAssertEqual(1, mockRuntime.createdSharedStates.count)  // only from onRegistered
    }
    
    func testReset() throws {
        // setup
        prepareConfig(privacy: .optedIn)
        let requestingEvent = getResetEvent()
        
        // test
        mockRuntime.simulateComingEvents(requestingEvent)
        
        // verify
        XCTAssertEqual(0, mockRuntime.dispatchedEvents.count)
        
        XCTAssertEqual(0, places.nearbyPois.count)
        XCTAssertEqual(0, places.userWithinPois.count)
        XCTAssertNil(places.currentPoi)
        XCTAssertNil(places.lastEnteredPoi)
        XCTAssertNil(places.lastExitedPoi)
        XCTAssertNil(places.membershipValidUntil)
        XCTAssertEqual(PlacesConstants.DefaultValues.INVALID_LAT_LON, places.lastKnownCoordinate.latitude)
        XCTAssertEqual(PlacesConstants.DefaultValues.INVALID_LAT_LON, places.lastKnownCoordinate.longitude)
        XCTAssertEqual(.notDetermined, places.authStatus)
        
        XCTAssertEqual(2, mockRuntime.createdSharedStates.count)  // first from onRegistered, second as result of this event
        let sharedState = mockRuntime.secondSharedState
        XCTAssertEqual(0, sharedState?.count)
    }
}
