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

enum PlacesConstants {
    static let EXTENSION_NAME = "com.adobe.module.places"
    static let EXTENSION_VERSION = "3.0.3"
    static let FRIENDLY_NAME = "Places"
    static let LOG_TAG = "Places"

    enum DefaultValues {
        static let MEMBERSHIP_TTL: TimeInterval = 60 * 60  // 1 hour in seconds
        static let NEARBY_POI_COUNT             = 10
        static let RADIUS                       = 1000     // 1 km
        static let INVALID_LAT_LON              = 999.999
    }

    enum UserDefaults {
        static let PLACES_DATA_STORE_NAME = "PlacesDataStore"

        static let PERSISTED_ACCURACY = "places_accuracy"
        static let PERSISTED_AUTH_STATUS = "places_auth_status"
        static let PERSISTED_CURRENT_POI = "places_current_poi"
        static let PERSISTED_LAST_ENTERED_POI = "places_last_entered_poi"
        static let PERSISTED_LAST_EXITED_POI = "places_last_exited_poi"
        static let PERSISTED_LATITUDE = "places_last_known_latitude"
        static let PERSISTED_LONGITUDE = "places_last_known_longitude"
        static let PERSISTED_MEMBERSHIP_VALID_UNTIL = "places_membership_valid_until"
        static let PERSISTED_NEARBY_POIS = "places_nearby_pois"
        static let PERSISTED_USER_WITHIN_POIS = "places_user_within_pois"
    }

    enum QueryService {
        static let PLACES_EDGE_QUERY = "placesedgequery"
        static let REQUEST_TIMEOUT: TimeInterval = 5

        enum Json {
            static let INPUT = "input"
            static let LATITUDE = "latitude"
            static let LIMIT = "limit"
            static let LONGITUDE = "longitude"
            static let META_DATA = "x"
            static let PLACES = "places"
            static let POI = "p"
            static let POIS = "pois"
            static let USER_WITHIN = "userWithin"
        }

        static let EXPECTED_ARRAY_LENGTH = 7
        enum Index {
            static let ID = 0
            static let NAME = 1
            static let LATITUDE = 2
            static let LONGITUDE = 3
            static let RADIUS = 4
            static let LIBRARY_ID = 5
            static let WEIGHT = 6
        }
    }

    enum SharedStateKey {
        static let ACCURACY = "accuracy"
        static let AUTH_STATUS = "authstatus"
        static let CURRENT_POI = "currentpoi"
        static let LAST_ENTERED_POI = "lastenteredpoi"
        static let LAST_EXITED_POI = "lastexitedpoi"
        static let NEARBY_POIS = "nearbypois"
        static let USER_WITHIN_POIS = "userwithinpois"
        static let VALID_UNTIL = "validuntil"
    }

    enum EventName {
        enum Request {
            static let GET_LAST_KNOWN_LOCATION = "requestgetlastknownlocation"
            static let GET_NEARBY_PLACES = "requestgetnearbyplaces"
            static let GET_USER_WITHIN_PLACES = "requestgetuserwithinplaces"
            static let PROCESS_REGION_EVENT = "requestprocessregionevent"
            static let RESET = "requestreset"
            static let SET_ACCURACY = "requestsetaccuracy"
            static let SET_AUTHORIZATION_STATUS = "requestsetauthorizationstatus"
        }

        enum Response {
            static let FAILURE = "responsefailure"
            static let GET_LAST_KNOWN_LOCATION = "responsegetlastknownlocation"
            static let GET_NEARBY_PLACES = "responsegetnearbyplaces"
            static let GET_USER_WITHIN_PLACES = "responsegetuserwithinplaces"
            static let PROCESS_REGION_EVENT = "responseprocessregionevent"
        }
    }

    enum EventDataKey {
        static let SHARED_STATE_OWNER = "stateowner"

        enum Configuration {
            static let SHARED_STATE_NAME = "com.adobe.module.configuration"

            static let BUILD_ENVIRONMENT = "build.environment"
            static let GLOBAL_CONFIG_PRIVACY = "global.privacy"
            static let PLACES_ENDPOINT = "places.endpoint"
            static let PLACES_LIBRARIES = "places.libraries"
            static let PLACES_LIBRARY_ID = "id"
            static let PLACES_LIBRARY_NAME = "name"
            static let PLACES_MEMBERSHIP_TTL = "places.membershipttl"
        }

        enum Places {
            static let SHARED_STATE_NAME = "com.adobe.module.places"

            static let ACCURACY = "accuracy"
            static let AUTH_STATUS = "authstatus"
            static let COUNT = "count"
            static let LATITUDE = "latitude"
            static let LIBRARY_ID = "libraryid"
            static let LONGITUDE = "longitude"
            static let POI = "poi"
            static let RADIUS = "radius"
            static let REGION_EVENT_TYPE = "regioneventtype"
            static let REGION_ID = "regionid"
            static let REGION_META_DATA = "regionmetadata"
            static let REGION_NAME = "regionname"
            static let REQUEST_TYPE = "requesttype"
            static let RESPONSE_STATUS = "status"
            static let TRIGGERING_REGION = "triggeringregion"
            static let USER_IS_WITHIN = "useriswithin"
            static let WEIGHT = "weight"

            enum RequestType {
                static let GET_LAST_KNOWN_LOCATION = "requestgetlastknownlocation"
                static let GET_NEARBY_PLACES = "requestgetnearbyplaces"
                static let GET_USER_WITHIN_PLACES = "requestgetuserwithinplaces"
                static let PROCESS_REGION_EVENT = "requestprocessregionevent"
                static let RESET = "requestreset"
                static let SET_ACCURACY = "requestsetaccuracy"
                static let SET_AUTHORIZATION_STATUS = "requestsetauthorizationstatus"
            }
        }
    }
}
