#!/bin/bash

# Builds a throwaway SPM package in Swift 6 language mode that calls every public AEPPlaces
# completion API with plain closures from @MainActor code. The SDK itself is not changed.

set -e # Any subsequent(*) commands which fail will cause the shell script to exit immediately

PROJECT_NAME=Swift6Consumer

# Clean up.
rm -rf $PROJECT_NAME

mkdir -p $PROJECT_NAME/Sources/$PROJECT_NAME && cd $PROJECT_NAME

# swiftLanguageMode needs PackageDescription 6.0. Only this test package uses it, the AEPPlaces manifest stays on 5.10.
echo "// swift-tools-version:6.0
import PackageDescription
let package = Package(
    name: \"$PROJECT_NAME\",
    platforms: [
        .iOS(.v15)
    ],
    products: [
        .library(name: \"$PROJECT_NAME\", targets: [\"$PROJECT_NAME\"])
    ],
    dependencies: [
        .package(name: \"AEPPlaces\", path: \"../\")
    ],
    targets: [
        .target(
            name: \"$PROJECT_NAME\",
            dependencies: [
                .product(name: \"AEPPlaces\", package: \"AEPPlaces\")
            ],
            swiftSettings: [.swiftLanguageMode(.v6)]
        )
    ]
)
" >Package.swift

cat > Sources/$PROJECT_NAME/$PROJECT_NAME.swift <<'EOF'
import AEPPlaces
import CoreLocation

@MainActor
final class Swift6Consumer {
    var nearbyCount = 0
    var nearbyResponseCode: PlacesQueryResponseCode = .unknownError
    var currentCount = 0
    var lastLatitude: Double?
    var lastLongitude: Double?

    func exercise() {
        let location = CLLocation(latitude: 37.3305, longitude: -121.8940)

        Places.getNearbyPointsOfInterest(forLocation: location, withLimit: 10) { pois, responseCode in
            let count = pois.count
            Task { @MainActor in
                self.nearbyCount = count
                self.nearbyResponseCode = responseCode
            }
        }

        Places.getCurrentPointsOfInterest { pois in
            let count = pois.count
            Task { @MainActor in self.currentCount = count }
        }

        Places.getLastKnownLocation { location in
            let latitude = location?.coordinate.latitude
            let longitude = location?.coordinate.longitude
            Task { @MainActor in
                self.lastLatitude = latitude
                self.lastLongitude = longitude
            }
        }
    }
}
EOF

swift package resolve

# This is necessary to avoid internal PIF error
swift package dump-pif > /dev/null

echo '############# Build Swift 6 consumer for generic iOS device ###############'
xcodebuild build -scheme $PROJECT_NAME -destination 'generic/platform=iOS'

# Clean up.
cd ../
rm -rf $PROJECT_NAME
