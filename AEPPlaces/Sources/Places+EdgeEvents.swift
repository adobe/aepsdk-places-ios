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

    func sendExperienceEventToEdge( poi: PointOfInterest, withRegionEventType type: PlacesRegionEvent) {

        // add eventType and prescribed data for the experience info
        var xdmMap: [String: Any] = [
            PlacesConstants.XDM.Key.EVENT_TYPE: type.toExperienceEventType(),
            PlacesConstants.XDM.Key.PLACE_CONTEXT: [
                PlacesConstants.XDM.Key.POI_INTERACTION: [
                    PlacesConstants.XDM.Key.POI_DETAIL: createXDMPOIDetail(poi: poi)
                ],
                PlacesConstants.XDM.Key.GEO: createXDMGeo(poi: poi)
            ]
        ]

        // Creating xdm edge event data
        let xdmEventData: [String: Any] = [
            PlacesConstants.XDM.Key.XDM: xdmMap

        ]
        
        // create the mask for storing event history
        let mask = [
            "xdm.eventType"
        ]

        // Creating xdm edge event with request content source type
        let event = Event(name: PlacesConstants.Event.Name.LOCATION_TRACKING,
                          type: EventType.edge,
                          source: EventSource.requestContent,
                          data: xdmEventData,
                          mask: mask)
        dispatch(event: event)
    }
    
    private func createXDMPOIDetail( poi : PointOfInterest) -> [String: Any] {
        let coordinates : [String: Any] = [
            PlacesConstants.XDM.Key.SCHEMA: [
                PlacesConstants.XDM.Key.LATITUDE: poi.latitude,
                PlacesConstants.XDM.Key.LONGITUDE: poi.longitude
            ]
        ]
        
        let circle : [String: Any] = [
            PlacesConstants.XDM.Key.SCHEMA: [
                PlacesConstants.XDM.Key.RADIUS: poi.radius,
                PlacesConstants.XDM.Key.COORDINATES: coordinates
            ]
        ]
        
        let geoShape: [String: Any] = [
            PlacesConstants.XDM.Key.SCHEMA: [
                PlacesConstants.XDM.Key.CIRCLE : circle
            ]
        ]
        
        let poiDetail: [String: Any] = [
            PlacesConstants.XDM.Key.POI_ID: poi.identifier,
            PlacesConstants.XDM.Key.NAME: poi.name,
            PlacesConstants.XDM.Key.CATEGORY: poi.metaData["category"],
            PlacesConstants.XDM.Key.GEO_INTERACTION_DETAILS: geoShape
        ]
        
        return poiDetail
    }
    
    private func createXDMGeo(poi: PointOfInterest) -> [String: Any] {
        let geo : [String: Any] = [
//            PlacesConstants.XDM.Key.COUNTRY_CODE: poi.metaData["country"],
            PlacesConstants.XDM.Key.STATE_PROVINCE: poi.metaData["state"],
            PlacesConstants.XDM.Key.CITY: poi.metaData["city"]
        ]
        return geo;
    }
}
