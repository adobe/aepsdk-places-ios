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

import Foundation
import AEPServices

/// Helps maintain the current state for the Places extension, including managing persistence and shared state
extension Places {
    // MARK: - internal functions

    /// Resets all the Places state data on the client and updates persistence
    func clearClientData() {
        nearbyPois.removeAll()
        userWithinPois.removeAll()
        currentPoi = nil
        lastEnteredPoi = nil
        lastExitedPoi = nil
        lastKnownCoordinate.latitude = PlacesConstants.DefaultValues.INVALID_LAT_LON
        lastKnownCoordinate.longitude = PlacesConstants.DefaultValues.INVALID_LAT_LON
        authStatus = .notDetermined
        accuracy = nil
        membershipValidUntil = nil

        updatePersistence()
    }

    /// Resets `currentPoi`, `lastEnteredPoi`, `lastExitedPoi`, and `membershipValidUntil` state values.
    /// Removes each of the above values from persistence.
    func clearMembershipData() {
        // clear locals
        currentPoi = nil
        lastEnteredPoi = nil
        lastExitedPoi = nil
        membershipValidUntil = nil

        // clear persistence
        dataStore.setCurrentPoi(nil)
        dataStore.setLastEnteredPoi(nil)
        dataStore.setLastExitedPoi(nil)
        dataStore.setMembershipValidUntil(nil)
    }

    /// Creates a dictionary representing the shared state for Places
    /// - Returns: a `[String: Any]` dictionary representing Places shared state
    func getSharedStateData() -> [String: Any] {
        var data: [String: Any] = [:]

        // ensure membership data is still valid and clear it out if it's expired
        if !membershipDataIsValid {
            clearMembershipData()
        }

        // add nearby points of interest
        if !nearbyPois.isEmpty {
            data[PlacesConstants.SharedStateKey.NEARBY_POIS] = nearbyPois.map { $1.mapValue }
        }

        // add the current poi
        if let currentPoi = currentPoi {
            data[PlacesConstants.SharedStateKey.CURRENT_POI] = currentPoi.mapValue
        }

        // add the last entered poi
        if let lastEnteredPoi = lastEnteredPoi {
            data[PlacesConstants.SharedStateKey.LAST_ENTERED_POI] = lastEnteredPoi.mapValue
        }

        // add the last exited poi
        if let lastExitedPoi = lastExitedPoi {
            data[PlacesConstants.SharedStateKey.LAST_EXITED_POI] = lastExitedPoi.mapValue
        }

        if #available(iOS 14, *), let accuracy = accuracy {
            data[PlacesConstants.SharedStateKey.ACCURACY] = accuracy.stringValue
        }

        // add location authorization status string
        data[PlacesConstants.SharedStateKey.AUTH_STATUS] = authStatus.stringValue

        // add membership timestamp
        data[PlacesConstants.SharedStateKey.VALID_UNTIL] = membershipValidUntil ?? 0 as TimeInterval

        return data
    }

    /// Reads all of the Places state values out of persistence and into local variables
    func loadPersistence() {
        nearbyPois = dataStore.nearbyPois
        userWithinPois = dataStore.userWithinPois
        currentPoi = dataStore.currentPoi
        lastEnteredPoi = dataStore.lastEnteredPoi
        lastExitedPoi = dataStore.lastExitedPoi
        lastKnownCoordinate.latitude = dataStore.lastKnownLatitude
        lastKnownCoordinate.longitude = dataStore.lastKnownLongitude
        accuracy = dataStore.accuracy
        authStatus = dataStore.authStatus
        membershipValidUntil = dataStore.membershipValidUntil
    }

    /// Set the Points of Interest near the current location of the device
    ///
    /// This method will update `currentPoi` and `lastEnteredPoi` when necessary.
    ///
    /// - Parameter pois: an array of new nearby Points of Interest that need to be processed
    func processNewNearbyPois(_ pois: [PointOfInterest]) {
        // current poi is always reset when we have a new list of POIs
        currentPoi = nil

        // quick check to make sure we have new pois
        if pois.isEmpty {
            nearbyPois.removeAll()
            userWithinPois.removeAll()
        } else {
            var newNearbyPois: [String: PointOfInterest] = [:]
            var newUserWithinPois: [String: PointOfInterest] = [:]
            var lastEnteredPoiHasBeenUpdated = false
            for poi in pois {
                // always add the poi to our list of new pois
                newNearbyPois[poi.identifier] = poi

                // check for poi membership
                if poi.userIsWithin {
                    // add poi to our list of new userWithinPois map
                    newUserWithinPois[poi.identifier] = poi

                    // the first poi in this list is the closest to the requested location, so we only
                    // want to set lastEnteredPoi one time while iterating in this loop
                    if !lastEnteredPoiHasBeenUpdated {
                        Log.trace(label: PlacesConstants.LOG_TAG, "\(#function) updating lastEnteredPoi - name: \(poi.name), identifier: \(poi.identifier).")
                        lastEnteredPoiHasBeenUpdated = true
                        lastEnteredPoi = poi
                    }

                    updateCurrentPoiIfNecessary(poi)
                }
            }

            nearbyPois = newNearbyPois
            userWithinPois = newUserWithinPois
        }

        updateMembershipValidUntil()
        updatePersistence()
    }

    /// Process a `PlacesRegionEvent` and update current, last entered, and last exited pois when applicable
    ///
    /// - Parameters:
    ///   - event: the type of region event being processed
    ///   - forPoi: the `PointOfInterest` that triggered the event
    func processRegionEvent(_ event: PlacesRegionEvent, forPoi poi: PointOfInterest) {
        switch event {
        case .entry:
            Log.trace(label: PlacesConstants.LOG_TAG, "\(#function) updating lastEnteredPoi - name: \(poi.name), identifier: \(poi.identifier).")
            lastEnteredPoi = poi
            userWithinPois[poi.identifier] = poi
        case .exit:
            Log.trace(label: PlacesConstants.LOG_TAG, "\(#function) updating lastExitedPoi - name: \(poi.name), identifier: \(poi.identifier).")
            lastExitedPoi = poi

            // reset the currentPoi so it can be recalculated later
            currentPoi = nil

            // remove the poi from our userWithinPois list
            userWithinPois.removeValue(forKey: poi.identifier)
        @unknown default:
            Log.trace(label: PlacesConstants.LOG_TAG, "\(#function) processing unknown region event - you shouldn't ever see this!")
            return
        }

        updateMembershipValidUntil()
        recalculateCurrentPoi()
        updatePersistence()
    }

    /// Updates the timestamp that determines the TTL for Places state data
    func updateMembershipValidUntil() {
        membershipValidUntil = (Date().timeIntervalSince1970 + membershipTtl).rounded()
        updatePersistence()
    }

    // MARK: - private functions

    /// Determines whether the current Places membership is still valid
    private var membershipDataIsValid: Bool {
        return Date().timeIntervalSince1970 < membershipValidUntil ?? 0
    }

    /// Loops through `userWithinPois` to appropriately set `currentPoi`
    private func recalculateCurrentPoi() {
        if userWithinPois.isEmpty {
            currentPoi = nil
            return
        }

        for poi in userWithinPois.values {
            updateCurrentPoiIfNecessary(poi)
        }
    }

    /// Compares the `currentPoi` to the provided `poi` and updates `currentPoi` if necessary
    /// See `PointOfInterest.hasPriorityOver` to understand how priority is calculated
    /// - Parameter poi: new `PointOfInterest` to compare against the existing `currentPoi`
    private func updateCurrentPoiIfNecessary(_ poi: PointOfInterest) {
        if currentPoi == nil || poi.hasPriorityOver(currentPoi!) {
            currentPoi = poi
        }
    }

    /// Saves all the local Places state variables into the persisted data store
    private func updatePersistence() {
        dataStore.setNearbyPois(nearbyPois)
        dataStore.setUserWithinPois(userWithinPois)
        dataStore.setCurrentPoi(currentPoi)
        dataStore.setLastEnteredPoi(lastEnteredPoi)
        dataStore.setLastExitedPoi(lastExitedPoi)
        dataStore.setLastKnownLatitude(lastKnownCoordinate.latitude)
        dataStore.setLastKnownLongitude(lastKnownCoordinate.longitude)
        dataStore.setAuthStatus(authStatus)
        dataStore.setAccuracy(accuracy)
        dataStore.setMembershipValidUntil(membershipValidUntil)
    }
}
