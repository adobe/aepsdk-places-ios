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

/// Represents a specific outcome resulting from an interaction with the Places Query Service.
// Passed to Sendable completion handlers, so it is marked Sendable for Swift 6.
@objc(AEPPlacesQueryResponseCode)
public enum PlacesQueryResponseCode: Int, Sendable {
    case ok = 0
    case connectivityError
    case serverResponseError
    case invalidLatLongError
    case configurationError
    case queryServiceUnavailable
    case privacyOptedOut
    case unknownError

    /// Converts an `Int` to its respective `PlacesQueryResponseCode`
    /// If `fromRawValue` is not a valid `PlacesQueryResponseCode`, calling this method will return `PlacesQueryResponseCode.unknownError`
    /// - Parameter fromRawValue: an `Int` representation of a `PlacesQueryResponseCode`
    /// - Returns: a `PlacesQueryResponseCode` representing the passed-in `Int`
    init(fromRawValue: Int) {
        self = PlacesQueryResponseCode(rawValue: fromRawValue) ?? .unknownError
    }
}
