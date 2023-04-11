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
import Foundation

/// Extension class providing streamlined access to data in `Event` objects.
extension Event {
    // MARK: - Event Type/Source/Owner Detection

    var isPlacesRequestEvent: Bool {
        type == EventType.places && source == EventSource.requestContent
    }

    var isSharedStateUpdateEvent: Bool {
        type == EventType.hub && source == EventSource.sharedState
    }

    // MARK: - Configuration, Privacy & Settings

    var sharedStateOwner: String? {
        data?[PlacesConstants.EventDataKey.SHARED_STATE_OWNER] as? String
    }

    var isConfigSharedStateChange: Bool {
        sharedStateOwner == PlacesConstants.EventDataKey.Configuration.SHARED_STATE_NAME
    }

    var privacyStatus: String? {
        data?[PlacesConstants.EventDataKey.Configuration.GLOBAL_CONFIG_PRIVACY] as? String
    }

    var locationAuthorizationStatus: String? {
        data?[PlacesConstants.EventDataKey.Places.AUTH_STATUS] as? String
    }

    var locationAccuracy: String? {
        data?[PlacesConstants.EventDataKey.Places.ACCURACY] as? String
    }

    // MARK: - Request Type handling

    var placesRequestType: String? {
        data?[PlacesConstants.EventDataKey.Places.REQUEST_TYPE] as? String
    }

    var isGetNearbyPlacesRequestType: Bool {
        placesRequestType == PlacesConstants.EventDataKey.Places.RequestType.GET_NEARBY_PLACES
    }

    var isProcessRegionEventRequestType: Bool {
        placesRequestType == PlacesConstants.EventDataKey.Places.RequestType.PROCESS_REGION_EVENT
    }

    var isGetUserWithinPlacesRequestType: Bool {
        placesRequestType == PlacesConstants.EventDataKey.Places.RequestType.GET_USER_WITHIN_PLACES
    }

    var isGetLastKnownLocationRequestType: Bool {
        placesRequestType == PlacesConstants.EventDataKey.Places.RequestType.GET_LAST_KNOWN_LOCATION
    }

    var isResetRequestType: Bool {
        placesRequestType == PlacesConstants.EventDataKey.Places.RequestType.RESET
    }

    var isSetAuthorizationStatusRequestType: Bool {
        placesRequestType == PlacesConstants.EventDataKey.Places.RequestType.SET_AUTHORIZATION_STATUS
    }

    var isSetAccuracyRequestType: Bool {
        placesRequestType == PlacesConstants.EventDataKey.Places.RequestType.SET_ACCURACY
    }

    // MARK: - Get Nearby Places

    var latitude: Double? {
        data?[PlacesConstants.EventDataKey.Places.LATITUDE] as? Double
    }

    var longitude: Double? {
        data?[PlacesConstants.EventDataKey.Places.LONGITUDE] as? Double
    }

    var requestedPoiCount: Int? {
        data?[PlacesConstants.EventDataKey.Places.COUNT] as? Int
    }

    var placesQueryResponseCode: PlacesQueryResponseCode? {
        PlacesQueryResponseCode(rawValue: data?[PlacesConstants.EventDataKey.Places.RESPONSE_STATUS] as? Int ?? -1)
    }

    var nearbyPois: [[String: Any]]? {
        data?[PlacesConstants.SharedStateKey.NEARBY_POIS] as? [[String: Any]]
    }

    var userWithinPois: [[String: Any]]? {
        data?[PlacesConstants.SharedStateKey.USER_WITHIN_POIS] as? [[String: Any]]
    }

    // MARK: - Process Region Events

    var regionId: String? {
        data?[PlacesConstants.EventDataKey.Places.REGION_ID] as? String
    }

    var regionEventType: PlacesRegionEvent? {
        PlacesRegionEvent.fromString(data?[PlacesConstants.EventDataKey.Places.REGION_EVENT_TYPE] as? String ?? "")
    }
}
