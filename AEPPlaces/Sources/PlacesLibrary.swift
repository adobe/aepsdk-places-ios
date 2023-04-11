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

/// Contains information defining a `PlacesLibrary`.
/// `PlacesLibrary` structs are primarily used in `PlacesConfiguration`.
struct PlacesLibrary: Codable {
    let id: String
    let name: String

    static func fromJsonString(_ jsonString: String) -> PlacesLibrary? {
        // because we are using .utf8 encoding, construction of this Data object should never return nil
        guard let jsonStringAsData = jsonString.data(using: .utf8) else {
            return nil
        }
        do {
            return try JSONDecoder().decode(PlacesLibrary.self, from: jsonStringAsData)
        } catch let error as NSError {
            Log.warning(label: PlacesConstants.LOG_TAG, "Unable to parse Places Library JSON: \(error.localizedDescription)")
            return nil
        }
    }

    func toJsonString() -> String? {
        do {
            let selfAsData = try JSONEncoder().encode(self)
            return String(data: selfAsData, encoding: .utf8)
        } catch let error as NSError {
            Log.warning(label: PlacesConstants.LOG_TAG, "Unable to serialize PlacesLibrary to JSON: \(error.localizedDescription)")
            return nil
        }
    }
}
