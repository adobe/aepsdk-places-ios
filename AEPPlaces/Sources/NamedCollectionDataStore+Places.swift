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

import AEPServices
import CoreLocation
import Foundation

/// Provides getters and setters for Places values that are persisted in a `NamedCollectionDataStore`
extension NamedCollectionDataStore {
    // MARK: - Getters

    var nearbyPois: [String: PointOfInterest] {
        if let persistedPois = getDictionary(key: PlacesConstants.UserDefaults.PERSISTED_NEARBY_POIS) as? [String: String] {
            var tempPois: [String: PointOfInterest] = [:]
            persistedPois.forEach { key, value in
                if let poi = try? PointOfInterest(jsonString: value) {
                    tempPois[key] = poi
                }
            }

            return tempPois
        } else {
            return [:]
        }
    }

    var userWithinPois: [String: PointOfInterest] {
        if let persistedPois = getDictionary(key: PlacesConstants.UserDefaults.PERSISTED_USER_WITHIN_POIS) as? [String: String] {
            var tempPois: [String: PointOfInterest] = [:]
            persistedPois.forEach { key, value in
                if let poi = try? PointOfInterest(jsonString: value) {
                    tempPois[key] = poi
                }
            }

            return tempPois
        } else {
            return [:]
        }
    }

    var currentPoi: PointOfInterest? {
        try? PointOfInterest(jsonString: getString(key: PlacesConstants.UserDefaults.PERSISTED_CURRENT_POI) ?? "")
    }

    var lastEnteredPoi: PointOfInterest? {
        try? PointOfInterest(jsonString: getString(key: PlacesConstants.UserDefaults.PERSISTED_LAST_ENTERED_POI) ?? "")
    }

    var lastExitedPoi: PointOfInterest? {
        try? PointOfInterest(jsonString: getString(key: PlacesConstants.UserDefaults.PERSISTED_LAST_EXITED_POI) ?? "")
    }

    var lastKnownLatitude: Double {
        getDouble(key: PlacesConstants.UserDefaults.PERSISTED_LATITUDE) ?? PlacesConstants.DefaultValues.INVALID_LAT_LON
    }

    var lastKnownLongitude: Double {
        getDouble(key: PlacesConstants.UserDefaults.PERSISTED_LONGITUDE) ?? PlacesConstants.DefaultValues.INVALID_LAT_LON
    }

    var accuracy: CLAccuracyAuthorization? {
        guard #available(iOS 14, *) else {
            return nil
        }

        if let persistedAccuracy = getString(key: PlacesConstants.UserDefaults.PERSISTED_ACCURACY) {
            return CLAccuracyAuthorization(fromString: persistedAccuracy)
        }

        return nil
    }

    var authStatus: CLAuthorizationStatus {
        CLAuthorizationStatus(fromString: getString(key: PlacesConstants.UserDefaults.PERSISTED_AUTH_STATUS) ?? "")
    }

    var membershipValidUntil: TimeInterval? {
        getDouble(key: PlacesConstants.UserDefaults.PERSISTED_MEMBERSHIP_VALID_UNTIL)
    }

    // MARK: - Setters

    func setNearbyPois(_ pois: [String: PointOfInterest]) {
        if !pois.isEmpty {
            var poiStringMap: [String: String] = [:]
            for currentPoi in pois {
                poiStringMap[currentPoi.key] = currentPoi.value.toJsonString()
            }
            set(key: PlacesConstants.UserDefaults.PERSISTED_NEARBY_POIS, value: poiStringMap)
        } else {
            remove(key: PlacesConstants.UserDefaults.PERSISTED_NEARBY_POIS)
        }
    }

    func setUserWithinPois(_ pois: [String: PointOfInterest]) {
        if !pois.isEmpty {
            var poiStringMap: [String: String] = [:]
            for currentPoi in pois {
                poiStringMap[currentPoi.key] = currentPoi.value.toJsonString()
            }
            set(key: PlacesConstants.UserDefaults.PERSISTED_USER_WITHIN_POIS, value: poiStringMap)
        } else {
            remove(key: PlacesConstants.UserDefaults.PERSISTED_USER_WITHIN_POIS)
        }
    }

    func setCurrentPoi(_ poi: PointOfInterest?) {
        if let poi = poi {
            set(key: PlacesConstants.UserDefaults.PERSISTED_CURRENT_POI, value: poi.toJsonString())
        } else {
            remove(key: PlacesConstants.UserDefaults.PERSISTED_CURRENT_POI)
        }
    }

    func setLastEnteredPoi(_ poi: PointOfInterest?) {
        if let poi = poi {
            set(key: PlacesConstants.UserDefaults.PERSISTED_LAST_ENTERED_POI, value: poi.toJsonString())
        } else {
            remove(key: PlacesConstants.UserDefaults.PERSISTED_LAST_ENTERED_POI)
        }
    }

    func setLastExitedPoi(_ poi: PointOfInterest?) {
        if let poi = poi {
            set(key: PlacesConstants.UserDefaults.PERSISTED_LAST_EXITED_POI, value: poi.toJsonString())
        } else {
            remove(key: PlacesConstants.UserDefaults.PERSISTED_LAST_EXITED_POI)
        }
    }

    func setLastKnownLatitude(_ lat: Double?) {
        if let lat = lat {
            set(key: PlacesConstants.UserDefaults.PERSISTED_LATITUDE, value: lat)
        } else {
            remove(key: PlacesConstants.UserDefaults.PERSISTED_LATITUDE)
        }
    }

    func setLastKnownLongitude(_ lon: Double?) {
        if let lon = lon {
            set(key: PlacesConstants.UserDefaults.PERSISTED_LONGITUDE, value: lon)
        } else {
            remove(key: PlacesConstants.UserDefaults.PERSISTED_LONGITUDE)
        }
    }

    func setAccuracy(_ accuracy: CLAccuracyAuthorization?) {
        guard #available(iOS 14, *) else {
            return
        }

        if let accuracy = accuracy {
            set(key: PlacesConstants.UserDefaults.PERSISTED_ACCURACY, value: accuracy.stringValue)
        } else {
            remove(key: PlacesConstants.UserDefaults.PERSISTED_ACCURACY)
        }
    }

    func setAuthStatus(_ status: CLAuthorizationStatus?) {
        if let status = status {
            set(key: PlacesConstants.UserDefaults.PERSISTED_AUTH_STATUS, value: status.stringValue)
        } else {
            remove(key: PlacesConstants.UserDefaults.PERSISTED_AUTH_STATUS)
        }
    }

    func setMembershipValidUntil(_ timestamp: TimeInterval?) {
        if let timestamp = timestamp {
            set(key: PlacesConstants.UserDefaults.PERSISTED_MEMBERSHIP_VALID_UNTIL, value: timestamp)
        } else {
            remove(key: PlacesConstants.UserDefaults.PERSISTED_MEMBERSHIP_VALID_UNTIL)
        }
    }
}
