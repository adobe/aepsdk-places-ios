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
import Foundation

/// Owns methods interfacing with the Places Edge Query Service.
class PlacesQueryService {
    /// Retrieves a list of nearby `PointsOfInterest` from the Places Edge Query Service.
    ///
    /// The `PlacesQueryServiceResult` passed to the closure will contain a `PlacesQueryResponseCode` value as well as
    /// an array of `PointOfInterest` objects. If the array is empty, consult the `PlacesQueryResponseCode` for more
    /// information.
    ///
    /// - Parameters:
    ///   - lat: the latitude (in degrees) of the device
    ///   - lon: the longitude (in degrees) of the device
    ///   - count: the maximum number of `PointOfInterest` objects to return in the `PlacesQueryServiceResult`
    ///   - configuration: contains the configuration details needed for making the network request
    ///   - completion: closure to be called with a `PlacesQueryServiceResult` when the network communications are complete
    func getNearbyPlaces(lat: Double, lon: Double, count: Int, configuration: PlacesConfiguration, completion: @escaping (PlacesQueryServiceResult) -> Void) {
        // make sure we have valid configuration
        if !configuration.isValid {
            Log.warning(label: PlacesConstants.LOG_TAG, "Call to retrieve nearby places from the Places Query Service failed - Places configuration is invalid.")
            completion(PlacesQueryServiceResult(response: .configurationError))
            return
        }

        // build the url to send to Places Query Service

        var components = URLComponents()
        components.scheme = "https"
        components.host = configuration.endpoint
        components.path = "/\(PlacesConstants.QueryService.PLACES_EDGE_QUERY)/"
        components.queryItems = getURLQueryItemsFor(libraries: configuration.libraries)
        components.queryItems?.append(contentsOf: [
            URLQueryItem(name: PlacesConstants.QueryService.Json.LATITUDE, value: String(lat)),
            URLQueryItem(name: PlacesConstants.QueryService.Json.LONGITUDE, value: String(lon)),
            URLQueryItem(name: PlacesConstants.QueryService.Json.LIMIT, value: String(count)),
        ])

        guard let url = components.url else {
            Log.warning(label: PlacesConstants.LOG_TAG, "Unable to request nearby places from the Places Query Service - error creating a URL object from components: \(components)")
            completion(PlacesQueryServiceResult(response: .configurationError))
            return
        }

        Log.trace(label: PlacesConstants.LOG_TAG, "Making a request to Places Query Service: \(url.absoluteString)")

        let networkService = ServiceProvider.shared.networkService
        let request = NetworkRequest(url: url,
                                     connectTimeout: PlacesConstants.QueryService.REQUEST_TIMEOUT,
                                     readTimeout: PlacesConstants.QueryService.REQUEST_TIMEOUT)

        networkService.connectAsync(networkRequest: request) { connection in
            if connection.responseCode == HttpConnectionConstants.ResponseCodes.HTTP_OK {
                guard let responseData = connection.data else {
                    Log.debug(label: PlacesConstants.LOG_TAG, "No nearby POIs.")
                    completion(PlacesQueryServiceResult(response: .ok))
                    return
                }

                guard let responseJson = try? JSONSerialization.jsonObject(with: responseData, options: .mutableContainers) as? [String: Any] else {
                    Log.debug(label: PlacesConstants.LOG_TAG, "Error parsing response from Places Query Service")
                    completion(PlacesQueryServiceResult(response: .serverResponseError))
                    return
                }

                guard let placesJson = responseJson[PlacesConstants.QueryService.Json.PLACES] as? [String: Any] else {
                    Log.debug(label: PlacesConstants.LOG_TAG, "No nearby POIs.")
                    completion(PlacesQueryServiceResult(response: .ok))
                    return
                }

                var nearbyPois: [PointOfInterest] = []

                // get pois that the user is within first
                if let membershipArray = placesJson[PlacesConstants.QueryService.Json.USER_WITHIN] as? [[String: Any]] {
                    for currentPoi in membershipArray {
                        if let poi = try? PointOfInterest(jsonObject: currentPoi, userIsWithin: true) {
                            nearbyPois.append(poi)
                        }
                    }
                }

                // get other pois that the user is near
                if let nearbyArray = placesJson[PlacesConstants.QueryService.Json.POIS] as? [[String: Any]] {
                    for currentPoi in nearbyArray {
                        if let poi = try? PointOfInterest(jsonObject: currentPoi) {
                            nearbyPois.append(poi)
                        }
                    }
                }

                Log.debug(label: PlacesConstants.LOG_TAG, "Response from Places Query Service contained \(nearbyPois.count) nearby POIs.")
                completion(PlacesQueryServiceResult(pois: nearbyPois, response: .ok))
            } else {
                Log.debug(label: PlacesConstants.LOG_TAG, "Places Query Service responded with status code \(connection.responseCode ?? 0)")
                completion(PlacesQueryServiceResult(response: .serverResponseError))
            }
        }
    }

    /// Returns an array of `URLQueryItem`s representing Places libraries for use in a request to the Places Edge Query Service
    ///
    /// The Places Edge Query Service expects libraries to be passed into the URL with the following format:
    ///   "library=LIBRARY_ONE&library=LIBRARY_TWO&library=LIBRARY_THREE" and so on.
    ///
    /// - Parameter libraries: an array of `PlacesLibrary` objects from which the URL parameter will be generated
    /// - Returns: `[URLQueryItem]` containing Places Library IDs
    private func getURLQueryItemsFor(libraries: [PlacesLibrary]) -> [URLQueryItem] {
        libraries.map {
            URLQueryItem(name: "library", value: $0.id)
        }
    }
}
