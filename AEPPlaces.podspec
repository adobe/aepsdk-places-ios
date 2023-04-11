Pod::Spec.new do |s|
  s.name         = "AEPPlaces"
  s.version      = "3.0.3"
  s.summary      = "Places extension for Adobe Experience Cloud SDK. Written and maintained by Adobe."
  s.description  = <<-DESC
                   The Places extension is used in conjunction with Adobe Experience Platform to deliver location functionality.
                   DESC

  s.homepage     = "https://github.com/adobe/aepsdk-places-ios.git"
  s.license      = { :type => "Apache License, Version 2.0", :file => "LICENSE" }
  s.author       = "Adobe Experience Platform Messaging SDK Team"
  s.source       = { :git => 'https://github.com/adobe/aepsdk-places-ios.git', :tag => s.version.to_s }
  s.platform = :ios, "10.0"
  s.swift_version = '5.1'

  s.pod_target_xcconfig = { 'BUILD_LIBRARY_FOR_DISTRIBUTION' => 'YES' }
  s.dependency 'AEPCore', '>= 3.0.0'
  s.dependency 'AEPServices', '>= 3.0.0'

  s.source_files = 'AEPPlaces/Sources/**/*.swift'

end
