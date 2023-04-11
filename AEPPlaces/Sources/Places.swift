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

import AEPCore
import AEPServices
import CoreLocation
import Foundation

/// Places class that extends `Extension` with the Adobe Core EventHub.
/// Responsible for handling and dispatching `Event`s
@objc(AEPMobilePlaces)
public class Places: NSObject, Extension {
    // MARK: - internal properties

    var nearbyPois: [String: PointOfInterest] = [:]
    var userWithinPois: [String: PointOfInterest] = [:]
    var currentPoi: PointOfInterest?
    var lastEnteredPoi: PointOfInterest?
    var lastExitedPoi: PointOfInterest?
    var lastKnownCoordinate: CLLocationCoordinate2D
    var membershipTtl: TimeInterval
    var membershipValidUntil: TimeInterval?
    var authStatus: CLAuthorizationStatus
    var accuracy: CLAccuracyAuthorization?
    var privacyStatus: PrivacyStatus
    var dataStore: NamedCollectionDataStore = .init(name: PlacesConstants.UserDefaults.PLACES_DATA_STORE_NAME)
    var placesQueryService = PlacesQueryService()

    // MARK: - Extension protocol

    // MARK: properties

    public static var extensionVersion: String = PlacesConstants.EXTENSION_VERSION
    public var name: String = PlacesConstants.EXTENSION_NAME
    public var friendlyName: String = PlacesConstants.FRIENDLY_NAME
    public var metadata: [String: String]?
    public var runtime: ExtensionRuntime

    // MARK: methods

    public required init?(runtime: ExtensionRuntime) {
        self.runtime = runtime

        lastKnownCoordinate = CLLocationCoordinate2D(latitude: PlacesConstants.DefaultValues.INVALID_LAT_LON,
                                                     longitude: PlacesConstants.DefaultValues.INVALID_LAT_LON)
        authStatus = .notDetermined
        privacyStatus = .unknown
        membershipTtl = PlacesConstants.DefaultValues.MEMBERSHIP_TTL

        super.init()
    }

    /// internal initializer only meant for use when unit testing - allows mocking of the query service
    internal init(runtime: ExtensionRuntime, queryService: PlacesQueryService) {
        self.runtime = runtime
        placesQueryService = queryService

        lastKnownCoordinate = CLLocationCoordinate2D(latitude: PlacesConstants.DefaultValues.INVALID_LAT_LON,
                                                     longitude: PlacesConstants.DefaultValues.INVALID_LAT_LON)
        authStatus = .notDetermined
        privacyStatus = .unknown
        membershipTtl = PlacesConstants.DefaultValues.MEMBERSHIP_TTL

        super.init()
    }

    public func onRegistered() {
        // register listener for shared state updates
        registerListener(type: EventType.hub, source: EventSource.sharedState, listener: handleSharedStateUpdate)

        // register listener for places request events
        registerListener(type: EventType.places, source: EventSource.requestContent, listener: handlePlacesRequest)

        // load persisted places state data and share it
        loadPersistence()
        createSharedState(data: getSharedStateData(), event: nil)
    }

    public func onUnregistered() {}

    public func readyForEvent(_ event: Event) -> Bool {
        getSharedState(extensionName: PlacesConstants.EventDataKey.Configuration.SHARED_STATE_NAME, event: event)?.status == .set
    }

    // MARK: - Listener Methods

    /// Handles configuration updates, stopping event processing and clearing shared state if the user has opted-out.
    ///
    /// - Parameter event: the SharedState update `Event`
    private func handleSharedStateUpdate(_ event: Event) {
        // for now, we are only handling configuration shared state updates
        if !event.isConfigSharedStateChange {
            return
        }

        guard let configSharedState = getSharedState(extensionName: PlacesConstants.EventDataKey.Configuration.SHARED_STATE_NAME, event: event) else {
            return
        }

        if configSharedState.globalPrivacy == .optedOut {
            Log.debug(label: PlacesConstants.LOG_TAG, "Stopping Places processing due to privacy opt-out")
            stopEvents()
            createSharedState(data: [:], event: event)
        }

        privacyStatus = configSharedState.globalPrivacy
    }

    /// Handles any Event with a type of `EventType.places`
    ///
    /// - Parameter event: the Places `Event` to be handled
    private func handlePlacesRequest(_ event: Event) {
        if event.isGetNearbyPlacesRequestType {
            handleGetNearbyPlacesRequest(event: event)
        } else if event.isProcessRegionEventRequestType {
            handleProcessRegionEventRequest(event: event)
        } else if event.isGetUserWithinPlacesRequestType {
            getUserWithinPlacesFor(event: event)
        } else if event.isGetLastKnownLocationRequestType {
            getLastKnownLocationFor(event: event)
        } else if event.isSetAuthorizationStatusRequestType {
            setAuthorizationStatusFrom(event: event)
        } else if event.isSetAccuracyRequestType {
            if #available(iOS 14, *) {
                setAccuracyFrom(event: event)
            }
        } else if event.isResetRequestType {
            reset()
        } else {
            Log.debug(label: PlacesConstants.LOG_TAG, "Ignoring a Places Request event due to a missing or unrecognized request type.")
        }
    }

    // MARK: - Private Methods

    private func handleGetNearbyPlacesRequest(event: Event) {
        // make sure the user isn't opted-out
        if privacyStatus == .optedOut {
            Log.trace(label: PlacesConstants.LOG_TAG, "Ignoring request to get nearby places - device has a privacy status of opted-out")
            let eventData = [PlacesConstants.EventDataKey.Places.RESPONSE_STATUS: PlacesQueryResponseCode.privacyOptedOut]
            dispatchResponseEventWith(name: PlacesConstants.EventName.Response.GET_NEARBY_PLACES,
                                      data: eventData,
                                      forEvent: event)
            return
        }

        // validate places configuration
        guard let placesConfig = getPlacesConfiguration(forEvent: event) else {
            Log.debug(label: PlacesConstants.LOG_TAG, "Places is not configured for this app.")
            let eventData = [PlacesConstants.EventDataKey.Places.RESPONSE_STATUS: PlacesQueryResponseCode.configurationError]
            dispatchResponseEventWith(name: PlacesConstants.EventName.Response.GET_NEARBY_PLACES,
                                      data: eventData,
                                      forEvent: event)
            return
        }

        if !placesConfig.isValid {
            Log.debug(label: PlacesConstants.LOG_TAG, "Places configuration for this app is invalid.")
            let eventData = [PlacesConstants.EventDataKey.Places.RESPONSE_STATUS: PlacesQueryResponseCode.configurationError]
            dispatchResponseEventWith(name: PlacesConstants.EventName.Response.GET_NEARBY_PLACES,
                                      data: eventData,
                                      forEvent: event)
            return
        }

        // validate necessary event data
        guard let latitude = event.latitude, let longitude = event.longitude else {
            Log.debug(label: PlacesConstants.LOG_TAG, "Latitude and Longitude are required parameters to retrieve nearby POI.")
            let eventData = [PlacesConstants.EventDataKey.Places.RESPONSE_STATUS: PlacesQueryResponseCode.invalidLatLongError]
            dispatchResponseEventWith(name: PlacesConstants.EventName.Response.GET_NEARBY_PLACES,
                                      data: eventData,
                                      forEvent: event)
            return
        }

        // update some of our state values
        lastKnownCoordinate.latitude = latitude
        lastKnownCoordinate.longitude = longitude
        membershipTtl = placesConfig.membershipTtl
        updateMembershipValidUntil()

        // prep request for places query service
        let count = event.requestedPoiCount ?? PlacesConstants.DefaultValues.NEARBY_POI_COUNT

        Log.debug(label: PlacesConstants.LOG_TAG, "Requesting \(count) nearby POIs for device location (\(latitude), \(longitude))")

        // get nearby pois from the query service
        placesQueryService.getNearbyPlaces(lat: latitude, lon: longitude, count: count, configuration: placesConfig) { result in
            // update shared state when we get a valid response
            if result.response == .ok {
                self.processNewNearbyPois(result.pois ?? [])
                self.createSharedState(data: self.getSharedStateData(), event: event)
            }

            // respond to the original event
            var nearbyPoiArray: [[String: Any]] = []
            for poi in result.pois ?? [] {
                nearbyPoiArray.append(poi.mapValue)
            }
            let eventData: [String: Any] = [
                PlacesConstants.EventDataKey.Places.RESPONSE_STATUS: result.response.rawValue,
                PlacesConstants.SharedStateKey.NEARBY_POIS: nearbyPoiArray,
            ]

            self.dispatchResponseEventWith(name: PlacesConstants.EventName.Response.GET_NEARBY_PLACES,
                                           data: eventData,
                                           forEvent: event)
            self.dispatchPlacesResponse(eventName: PlacesConstants.EventName.Response.GET_NEARBY_PLACES, data: eventData)
        }
    }

    private func handleProcessRegionEventRequest(event: Event) {
        // make sure the user isn't opted-out
        if privacyStatus == .optedOut {
            Log.trace(label: PlacesConstants.LOG_TAG, "Ignoring request to process region event - device has a privacy status of opted-out.")
            return
        }

        // validate places configuration
        guard let placesConfig = getPlacesConfiguration(forEvent: event) else {
            Log.debug(label: PlacesConstants.LOG_TAG, "Places is not configured for this app.")
            return
        }

        if !placesConfig.isValid {
            Log.debug(label: PlacesConstants.LOG_TAG, "Places configuration for this app is invalid.")
            return
        }

        // validate event data
        guard let regionId = event.regionId, let regionEventType = event.regionEventType else {
            Log.debug(label: PlacesConstants.LOG_TAG, "Ignoring request to process region event - 'regionid' and 'regioneventtype' are required fields but are missing.")
            return
        }

        // make sure the regionId is in our list of nearby pois
        // this check is used to sanitize the region event, helping prevent a stale region event from being processed
        guard let triggeringPoi = nearbyPois[regionId] else {
            Log.debug(label: PlacesConstants.LOG_TAG, "Unable to process a region event for a POI that is not in the list of nearbyPois.")
            return
        }

        membershipTtl = placesConfig.membershipTtl

        Log.debug(label: PlacesConstants.LOG_TAG, "Processing region \(regionEventType) event for region '\(triggeringPoi.name)'")

        processRegionEvent(regionEventType, forPoi: triggeringPoi)

        dispatchRegionEventFor(poi: triggeringPoi, withRegionEventType: regionEventType)

        sendExperienceEventToEdge(event: event, poi: triggeringPoi, withRegionEventType: regionEventType)
    }

    private func getPlacesConfiguration(forEvent event: Event) -> PlacesConfiguration? {
        guard let configSharedState = getSharedState(extensionName: PlacesConstants.EventDataKey.Configuration.SHARED_STATE_NAME, event: event) else {
            return nil
        }
        return PlacesConfiguration.fromSharedState(configSharedState)
    }

    private func getUserWithinPlacesFor(event: Event) {
        Log.trace(label: PlacesConstants.LOG_TAG, "Getting user-within Points of Interest.")

        // convert the map of userWithinPois to an array to put in the eventData
        let userWithinPoiArray = userWithinPois.values.map { $0.mapValue }

        let eventData = [
            PlacesConstants.SharedStateKey.USER_WITHIN_POIS: userWithinPoiArray,
        ]

        dispatchResponseEventWith(name: PlacesConstants.EventName.Response.GET_USER_WITHIN_PLACES,
                                  data: eventData,
                                  forEvent: event)
        dispatchPlacesResponse(eventName: PlacesConstants.EventName.Response.GET_USER_WITHIN_PLACES, data: eventData)
    }

    private func getLastKnownLocationFor(event: Event) {
        Log.trace(label: PlacesConstants.LOG_TAG, "Getting last know user location.")

        let eventData = [
            PlacesConstants.EventDataKey.Places.LATITUDE: lastKnownCoordinate.latitude,
            PlacesConstants.EventDataKey.Places.LONGITUDE: lastKnownCoordinate.longitude,
        ]

        dispatchResponseEventWith(name: PlacesConstants.EventName.Response.GET_LAST_KNOWN_LOCATION,
                                  data: eventData,
                                  forEvent: event)
        dispatchPlacesResponse(eventName: PlacesConstants.EventName.Response.GET_LAST_KNOWN_LOCATION, data: eventData)
    }

    private func setAuthorizationStatusFrom(event: Event) {
        if let status = event.locationAuthorizationStatus {
            authStatus = CLAuthorizationStatus(fromString: status)
            createSharedState(data: getSharedStateData(), event: event)
            Log.debug(label: PlacesConstants.LOG_TAG, "Setting location authorization status for Places: \(authStatus.stringValue)")
        }
    }

    @available(iOS 14, *)
    private func setAccuracyFrom(event: Event) {
        if let eventAccuracy = event.locationAccuracy, let newAccuracy = CLAccuracyAuthorization(fromString: eventAccuracy) {
            accuracy = newAccuracy
            createSharedState(data: getSharedStateData(), event: event)
            Log.debug(label: PlacesConstants.LOG_TAG, "Setting location accuracy for Places: \(newAccuracy.stringValue)")
        }
    }

    private func reset() {
        clearClientData()
        createSharedState(data: [:], event: nil)
        Log.debug(label: PlacesConstants.LOG_TAG, "Places shared state and persisted data has been reset.")
    }

    private func dispatchPlacesResponse(eventName: String, data: [String: Any]) {
        // then generic response event
        let event = Event(name: eventName, type: EventType.places, source: EventSource.responseContent, data: data)
        dispatch(event: event)
    }

    private func dispatchRegionEventFor(poi: PointOfInterest, withRegionEventType type: PlacesRegionEvent) {
        let eventData: [String: Any] = [
            PlacesConstants.EventDataKey.Places.TRIGGERING_REGION: poi.mapValue,
            PlacesConstants.EventDataKey.Places.REGION_EVENT_TYPE: type.stringValue,
        ]
        let event = Event(name: PlacesConstants.EventName.Response.PROCESS_REGION_EVENT,
                          type: EventType.places, source: EventSource.responseContent, data: eventData)

        createSharedState(data: getSharedStateData(), event: nil)
        dispatch(event: event)
    }

    private func dispatchResponseEventWith(name: String, data: [String: Any], forEvent event: Event) {
        let responseEvent = event.createResponseEvent(name: name,
                                                      type: EventType.places,
                                                      source: EventSource.responseContent,
                                                      data: data)
        dispatch(event: responseEvent)
    }
}
