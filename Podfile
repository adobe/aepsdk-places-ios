# Uncomment the next line to define a global platform for your project
platform :ios, '10.0'

# Comment the next line if you don't want to use dynamic frameworks
use_frameworks!

# don't warn me
install! 'cocoapods', :warn_for_unused_master_specs_repo => false

workspace 'AEPPlaces'
project 'AEPPlaces.xcodeproj'

# ==================
# SHARED POD GROUPS
# ==================
# development against main branches of dependencies
def dev_main
    pod 'AEPCore'
    pod 'AEPServices'
end

# development against dev branches of dependencies
def dev_dev
    pod 'AEPCore', :git => 'https://github.com/adobe/aepsdk-core-ios.git', :branch => 'dev-v3.1.2'
    pod 'AEPServices', :git => 'https://github.com/adobe/aepsdk-core-ios.git', :branch => 'dev-v3.1.2'
end

# test app against main branches
def test_main
    dev_main
    pod 'AEPAnalytics'
    pod 'AEPIdentity'
    pod 'AEPLifecycle'
    pod 'AEPSignal'
    pod 'AEPAssurance'
    pod 'AEPEdgeIdentity'
    pod 'AEPEdge'
    pod 'ACPCore', :git => 'https://github.com/adobe/aep-sdk-compatibility-ios.git', :branch => 'main'
end

# test app against dev branches
def test_dev
    dev_dev
    pod 'AEPAnalytics', :git => 'https://github.com/adobe/aepsdk-analytics-ios.git', :branch => 'dev-v3.0.2'
    pod 'AEPIdentity', :git => 'https://github.com/adobe/aepsdk-core-ios.git', :branch => 'dev-v3.1.2'
    pod 'AEPLifecycle', :git => 'https://github.com/adobe/aepsdk-core-ios.git', :branch => 'dev-v3.1.2'
    pod 'AEPSignal', :git => 'https://github.com/adobe/aepsdk-core-ios.git', :branch => 'dev-v3.1.2'
    pod 'AEPAssurance' #todo - get a link to this repo once it's public
    pod 'ACPCore', :git => 'https://github.com/adobe/aep-sdk-compatibility-ios.git', :branch => 'main'
end

# ==================
# TARGET DEFINITIONS
# ==================
target 'AEPPlaces' do
    dev_main
end

target 'AEPPlacesTests' do
    dev_main
end

target 'PlacesTestApp' do
    test_main
end

target 'PlacesTestApp_objc' do
    test_main
end
