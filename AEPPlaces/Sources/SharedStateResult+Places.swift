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

/// Extension class providing streamlined access to Places data in `SharedStateResult` objects.
extension SharedStateResult {
    // MARK: - Configuration

    var placesLibraries: [[String: Any]]? {
        value?[PlacesConstants.EventDataKey.Configuration.PLACES_LIBRARIES] as? [[String: Any]]
    }

    var placesEndpoint: String? {
        value?[PlacesConstants.EventDataKey.Configuration.PLACES_ENDPOINT] as? String
    }

    var placesMembershipTtl: TimeInterval? {
        value?[PlacesConstants.EventDataKey.Configuration.PLACES_MEMBERSHIP_TTL] as? TimeInterval
    }

    var globalPrivacy: PrivacyStatus {
        PrivacyStatus(rawValue: value?[PlacesConstants.EventDataKey.Configuration.GLOBAL_CONFIG_PRIVACY] as? String ?? "unknown")!
    }

    var experienceEventDataset: String? {
        value?[PlacesConstants.SharedState.Configuration.EXPERIENCE_EVENT_DATASET] as? String
    }
}
