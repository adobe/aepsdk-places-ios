/*
 Copyright 2022 Adobe. All rights reserved.
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
import Foundation

extension Places {
    func sendExperienceEventToEdge(event: Event, poi: PointOfInterest, withRegionEventType type: PlacesRegionEvent) {
        // an experience event dataset id is required for sending a message
        guard let datasetId = getDatasetId(forEvent: event) else {
            Log.warning(label: PlacesConstants.LOG_TAG, "Unable to record location event - unable to obtain AJO dataset.")
            return
        }

        // add eventType and prescribed data for the experience info
        var poiInteraction: [String: Any] = [
            PlacesConstants.XDM.Key.POI_DETAIL: createXDMPOIDetail(poi: poi),
        ]

        if type == PlacesRegionEvent.entry {
            poiInteraction[PlacesConstants.XDM.Key.POIENTRIES] = createPOIEntriesExits(poi: poi)
        } else {
            poiInteraction[PlacesConstants.XDM.Key.POIEXITS] = createPOIEntriesExits(poi: poi)
        }

        let xdmMap: [String: Any] = [
            PlacesConstants.XDM.Key.EVENT_TYPE: type.toExperienceEventType(),
            PlacesConstants.XDM.Key.PLACE_CONTEXT: [
                PlacesConstants.XDM.Key.POI_INTERACTION: poiInteraction,
            ],
        ]

        // Creating xdm edge event data
        let xdmEventData: [String: Any] = [
            PlacesConstants.XDM.Key.XDM: xdmMap,
            PlacesConstants.XDM.Key.META: [
                PlacesConstants.XDM.Key.COLLECT: [
                    PlacesConstants.XDM.Key.DATASET_ID: datasetId,
                ],
            ],
        ]

        // create the mask for storing event history
        let mask = [
            "xdm.eventType",
        ]

        // Creating xdm edge event with request content source type
        let event = Event(name: PlacesConstants.EventName.Request.LOCATION_TRACKING,
                          type: EventType.edge,
                          source: EventSource.requestContent,
                          data: xdmEventData,
                          mask: mask)
        dispatch(event: event)
    }

    private func createXDMPOIDetail(poi: PointOfInterest) -> [String: Any] {
        let coordinates: [String: Any] = [
            PlacesConstants.XDM.Key.SCHEMA: [
                PlacesConstants.XDM.Key.LATITUDE: poi.latitude,
                PlacesConstants.XDM.Key.LONGITUDE: poi.longitude,
            ],
        ]

        let circle: [String: Any] = [
            PlacesConstants.XDM.Key.SCHEMA: [
                PlacesConstants.XDM.Key.RADIUS: poi.radius,
                PlacesConstants.XDM.Key.COORDINATES: coordinates,
            ],
        ]

        let geoShape: [String: Any] = [
            PlacesConstants.XDM.Key.SCHEMA: [
                PlacesConstants.XDM.Key.CIRCLE: circle,
            ],
        ]

        var poiDetail: [String: Any] = [
            PlacesConstants.XDM.Key.POI_ID: poi.identifier,
            PlacesConstants.XDM.Key.NAME: poi.name,
            PlacesConstants.XDM.Key.GEO_INTERACTION_DETAILS: geoShape,
            PlacesConstants.XDM.Key.METADATA: createPOIMetadata(poi: poi),
        ]

        if poi.metaData["category"] != nil {
            poiDetail[PlacesConstants.XDM.Key.CATEGORY] = poi.metaData["category"]
        }

        return poiDetail
    }

    private func createPOIMetadata(poi: PointOfInterest) -> [String: Any] {
        var list = [[String: Any]]()

        for (metaKey, metaValue) in poi.metaData {
            let metaTuple: [String: Any] = [
                PlacesConstants.XDM.Key.KEY: metaKey,
                PlacesConstants.XDM.Key.VALUE: metaValue,
            ]

            list.append(metaTuple)
        }

        let metadata: [String: Any] = [PlacesConstants.XDM.Key.LIST: list]
        return metadata
    }

    private func createPOIEntriesExits(poi: PointOfInterest) -> [String: Any] {
        let poiEntriesExits: [String: Any] = [
            PlacesConstants.XDM.Key.ID: poi.identifier,
            PlacesConstants.XDM.Key.VALUE: 1,
        ]
        return poiEntriesExits
    }

    /// Retrieves the Messaging event datasetId from configuration shared state
    ///
    /// - Parameter event: the `Event` needed for retrieving the correct shared state
    /// - Returns: a `String` containing the event datasetId for Messaging
    private func getDatasetId(forEvent event: Event? = nil) -> String? {
        guard let configuration = getSharedState(extensionName: PlacesConstants.SharedState.Configuration.NAME, event: event),
              let datasetId = configuration.experienceEventDataset
        else {
            return nil
        }

        return datasetId.isEmpty ? nil : datasetId
    }
}
