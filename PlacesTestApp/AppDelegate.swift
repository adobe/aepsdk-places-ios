//
//  AppDelegate.swift
//  PlacesTestApp
//
//  Created by steve benedick on 4/30/21.
//

import UIKit
import AEPCore
import AEPPlaces
import ACPCore
import AEPAssurance


@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        MobileCore.setLogLevel(.trace)
        
        // steve-places in Adobe Benedick Corp: launch-EN459260fc579a4dcbb2d1743947e65f09-development
        MobileCore.configureWith(appId: "launch-EN459260fc579a4dcbb2d1743947e65f09-development")
        
        try? ACPCore.registerExtension(AEPAssurance.self)
        MobileCore.registerExtensions([Places.self]) {
            AEPAssurance.startSession(URL(string: "aepplaces://?adb_validation_sessionid=ecc9abb0-9028-4312-bc1d-a16920353e79")!)
        }
        
        return true
    }

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }


}

