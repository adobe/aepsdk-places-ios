# Uncomment the next line to define a global platform for your project
platform :ios, '15.0'

# Comment the next line if you don't want to use dynamic frameworks
use_frameworks!

$dev_repo = 'https://github.com/adobe/aepsdk-core-ios.git'
$dev_branch = 'staging'

# don't warn me
install! 'cocoapods', :warn_for_unused_master_specs_repo => false

workspace 'AEPPlaces'
project 'AEPPlaces.xcodeproj'

pod 'SwiftLint', '0.52.0'

# ==================
# SHARED POD GROUPS
# ==================
# development against main branches of dependencies
def dev_main
    pod 'AEPCore'
    pod 'AEPServices'
    pod 'AEPRulesEngine'
end

# development against dev branches of dependencies
def dev_dev
    pod 'AEPCore', :git => $dev_repo, :branch => $dev_branch
    pod 'AEPServices', :git => $dev_repo, :branch => $dev_branch
    pod 'AEPRulesEngine' #, :git => 'https://github.com/adobe/aepsdk-rulesengine-ios.git', :branch => 'dev-v5.0.0'
end

# test app against main branches
def test_main
    dev_main
    pod 'AEPAnalytics'
    pod 'AEPIdentity'
    pod 'AEPLifecycle'
    pod 'AEPSignal'
    pod 'AEPAssurance', :git => 'https://github.com/adobe/aepsdk-assurance-ios.git', :branch => 'staging'
    pod 'AEPEdgeIdentity'
    pod 'AEPEdgeConsent'
    pod 'AEPEdge'
end

# test app against dev branches
def test_dev
    dev_dev
    pod 'AEPIdentity', :git => $dev_repo, :branch => $dev_branch
    pod 'AEPLifecycle', :git => $dev_repo, :branch => $dev_branch
    pod 'AEPSignal', :git => $dev_repo, :branch => $dev_branch
    
    pod 'AEPAnalytics'
    pod 'AEPAssurance', :git => 'https://github.com/adobe/aepsdk-assurance-ios.git', :branch => 'dev-v5.0.0'        
    pod 'AEPEdge', :git => 'https://github.com/adobe/aepsdk-edge-ios.git', :branch => 'dev-v5.0.0'
    pod 'AEPEdgeConsent', :git => 'https://github.com/adobe/aepsdk-edgeconsent-ios.git', :branch => 'dev-v5.0.0'
    pod 'AEPEdgeIdentity', :git => 'https://github.com/adobe/aepsdk-edgeidentity-ios.git', :branch => 'dev-v5.0.0'
end

# ==================
# TARGET DEFINITIONS
# ==================
target 'AEPPlaces' do
    dev_main
end

target 'AEPPlacesTests' do
    dev_main
    pod 'AEPTestUtils', :git => 'https://github.com/adobe/aepsdk-core-ios.git', :tag => 'testutils-5.6.0'
end

target 'PlacesTestApp' do
    test_main
end

target 'PlacesTestApp_objc' do
    test_main
end

post_install do |pi|
  pi.pods_project.targets.each do |t|
    t.build_configurations.each do |bc|
      bc.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '15.0'
    end
  end
end
