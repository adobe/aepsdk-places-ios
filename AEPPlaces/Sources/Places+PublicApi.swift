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

/// Defines the public interface for the Places extension.
@objc
public extension Places {
    /// Clears out the client-side data for Places in shared state, local storage, and in-memory.
    static func clear() {
        let eventData: [String: Any] = [
            PlacesConstants.EventDataKey.Places.REQUEST_TYPE: PlacesConstants.EventDataKey.Places.RequestType.RESET,
        ]
        let event = Event(name: PlacesConstants.EventName.Request.RESET,
                          type: EventType.places,
                          source: EventSource.requestContent,
                          data: eventData)

        Log.trace(label: PlacesConstants.LOG_TAG, "Requesting reset of Places state and data.")

        MobileCore.dispatch(event: event)
    }

    /// Returns all Points of Interest (POI) of which the device is currently known to be within.
    ///
    /// - Parameter closure: called with an array of `PointOfInterest` objects that represent the user-within POIs
    static func getCurrentPointsOfInterest(_ closure: @escaping ([PointOfInterest]) -> Void) {
        let eventData: [String: Any] = [
            PlacesConstants.EventDataKey.Places.REQUEST_TYPE: PlacesConstants.EventDataKey.Places.RequestType.GET_USER_WITHIN_PLACES,
        ]

        let event = Event(name: PlacesConstants.EventName.Request.GET_USER_WITHIN_PLACES,
                          type: EventType.places,
                          source: EventSource.requestContent,
                          data: eventData)

        MobileCore.dispatch(event: event, timeout: 2) { responseEvent in
            guard let pois = responseEvent?.userWithinPois else {
                closure([])
                return
            }

            var convertedPois: [PointOfInterest] = []
            for currentMap in pois {
                if let currentAsJsonData = try? JSONSerialization.data(withJSONObject: currentMap, options: []),
                   let currentJsonString = String(data: currentAsJsonData, encoding: .utf8),
                   let convertedPoi = try? PointOfInterest(jsonString: currentJsonString) {
                    convertedPois.append(convertedPoi)
                }
            }
            closure(convertedPois)
        }
    }

    /// Returns the last latitude and longitude provided to the AEPPlaces Extension.
    ///
    /// If the Places Extension does not have a valid last known location for the user, the parameter passed
    /// in the closure will be `nil`.
    /// The CLLocation object returned by this method will only ever contain valid data for latitude and longitude,
    /// and is not meant to be used for plotting course, speed, altitude, etc.
    ///
    /// - Parameter closure: called with a `CLLocation` object representing the last known lat/lon provided to
    ///                      the `Places` extension
    static func getLastKnownLocation(_ closure: @escaping (CLLocation?) -> Void) {
        let eventData: [String: Any] = [
            PlacesConstants.EventDataKey.Places.REQUEST_TYPE: PlacesConstants.EventDataKey.Places.RequestType.GET_LAST_KNOWN_LOCATION,
        ]

        let event = Event(name: PlacesConstants.EventName.Request.GET_LAST_KNOWN_LOCATION,
                          type: EventType.places,
                          source: EventSource.requestContent,
                          data: eventData)

        MobileCore.dispatch(event: event, timeout: 2) { responseEvent in
            guard let lat = responseEvent?.latitude, let lon = responseEvent?.longitude else {
                closure(nil)
                return
            }

            let lastLocation = CLLocation(latitude: lat, longitude: lon)
            closure(lastLocation)
        }
    }

    /// Requests a list of nearby Points of Interest (POI) and returns them in a closure.
    ///
    /// - Parameters:
    ///   - location: a CLLocation object represent the current location of the device
    ///   - limit: a non-negative number representing the number of nearby POI to return from the request
    ///   - closure: called with an array of `PointOfInterest` objects that represent the nearest POI to the device and a `PlacesQueryResponseCode`
    @objc(getNearbyPointsOfInterest:limit:callback:)
    static func getNearbyPointsOfInterest(forLocation location: CLLocation,
                                          withLimit limit: UInt,
                                          closure: @escaping ([PointOfInterest], PlacesQueryResponseCode) -> Void) {
        let eventData: [String: Any] = [
            PlacesConstants.EventDataKey.Places.REQUEST_TYPE: PlacesConstants.EventDataKey.Places.RequestType.GET_NEARBY_PLACES,
            PlacesConstants.EventDataKey.Places.LATITUDE: location.coordinate.latitude,
            PlacesConstants.EventDataKey.Places.LONGITUDE: location.coordinate.longitude,
            PlacesConstants.EventDataKey.Places.COUNT: limit,
        ]

        let event = Event(name: PlacesConstants.EventName.Request.GET_NEARBY_PLACES,
                          type: EventType.places,
                          source: EventSource.requestContent,
                          data: eventData)

        MobileCore.dispatch(event: event, timeout: 5) { responseEvent in
            guard let pois = responseEvent?.nearbyPois, let responseCode = responseEvent?.placesQueryResponseCode else {
                closure([], PlacesQueryResponseCode.unknownError)
                return
            }

            if responseCode == .ok {
                var convertedPois: [PointOfInterest] = []
                for currentMap in pois {
                    if let currentAsJsonData = try? JSONSerialization.data(withJSONObject: currentMap, options: []),
                       let currentJsonString = String(data: currentAsJsonData, encoding: .utf8),
                       let convertedPoi = try? PointOfInterest(jsonString: currentJsonString) {
                        convertedPois.append(convertedPoi)
                    }
                }
                closure(convertedPois, responseCode)
            } else {
                closure([], responseCode)
            }
        }
    }

    /// Passes a `CLRegion` and a `PlacesRegionEvent` to be processed by the Places extension.
    ///
    /// Calling this method will result in an Event being dispatched to the SDK's EventHub.
    /// This enables rule processing based on the triggering region event.
    ///
    /// - Parameters:
    ///   - regionEvent: value indicating whether the device entered or exited the given region
    ///   - region: the `CLRegion` object that triggered the event
    static func processRegionEvent(_ regionEvent: PlacesRegionEvent,
                                   forRegion region: CLRegion) {
        let eventData: [String: Any] = [
            PlacesConstants.EventDataKey.Places.REQUEST_TYPE: PlacesConstants.EventDataKey.Places.RequestType.PROCESS_REGION_EVENT,
            PlacesConstants.EventDataKey.Places.REGION_ID: region.identifier,
            PlacesConstants.EventDataKey.Places.REGION_EVENT_TYPE: regionEvent.stringValue,
        ]

        let event = Event(name: PlacesConstants.EventName.Request.PROCESS_REGION_EVENT,
                          type: EventType.places,
                          source: EventSource.requestContent,
                          data: eventData)

        Log.trace(label: PlacesConstants.LOG_TAG, "Dispatching region '\(regionEvent.stringValue)' event for POI ID '\(region.identifier)'")

        MobileCore.dispatch(event: event)
    }

    /// Sets the accuracy authorization in the Places extension.
    ///
    /// The status provided is stored in the Places shared state, and is for reference only.
    /// Calling this method does not impact the actual location accuracy setting for this device.
    ///
    /// This method is only available on iOS 14 and newer.
    ///
    /// - Parameter accuracy: the CLAccuracyAuthorization to be set for this device
    @available(iOS 14, *)
    @objc(setAccuracyAuthorization:)
    static func setAccuracyAuthorization(_ accuracy: CLAccuracyAuthorization) {
        let eventData: [String: Any] = [
            PlacesConstants.EventDataKey.Places.REQUEST_TYPE: PlacesConstants.EventDataKey.Places.RequestType.SET_ACCURACY,
            PlacesConstants.EventDataKey.Places.ACCURACY: accuracy.stringValue,
        ]

        let event = Event(name: PlacesConstants.EventName.Request.SET_ACCURACY,
                          type: EventType.places,
                          source: EventSource.requestContent,
                          data: eventData)

        MobileCore.dispatch(event: event)
    }

    /// Sets the authorization status in the Places extension.
    ///
    /// The status provided is stored in the Places shared state, and is for reference only.
    /// Calling this method does not impact the actual location authorization status for this device.
    ///
    /// - Parameter status: the CLAuthorizationStatus to be set for this device
    @objc(setAuthorizationStatus:)
    static func setAuthorizationStatus(_ status: CLAuthorizationStatus) {
        let eventData: [String: Any] = [
            PlacesConstants.EventDataKey.Places.REQUEST_TYPE: PlacesConstants.EventDataKey.Places.RequestType.SET_AUTHORIZATION_STATUS,
            PlacesConstants.EventDataKey.Places.AUTH_STATUS: status.stringValue,
        ]

        let event = Event(name: PlacesConstants.EventName.Request.SET_AUTHORIZATION_STATUS,
                          type: EventType.places,
                          source: EventSource.requestContent,
                          data: eventData)

        MobileCore.dispatch(event: event)
    }
}
