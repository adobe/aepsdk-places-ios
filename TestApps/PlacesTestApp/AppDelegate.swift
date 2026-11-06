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

import UIKit
import AEPCore
import AEPPlaces
import AEPAssurance
import AEPSignal
import AEPAnalytics
import AEPIdentity
import AEPLifecycle
import AEPEdgeIdentity
import AEPEdge
import AEPEdgeConsent

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        MobileCore.setLogLevel(.trace)

        MobileCore.configureWith(appId: "")
        
        let appState = application.applicationState
        // AEPIdentity and AEPEdgeIdentity both export Identity, so the module name is needed to pick the right one.
        MobileCore.registerExtensions([Places.self, Signal.self, Analytics.self, AEPIdentity.Identity.self, Lifecycle.self, Assurance.self,  AEPEdgeIdentity.Identity.self, Edge.self, Consent.self]) {
            Assurance.startSession(url: URL(string: "<YOUR_SESSION_ID>"))
            if appState != .background {
                MobileCore.lifecycleStart(additionalContextData: nil)
            }
        }

        return true
    }

    // MARK: UISceneSession Lifecycle

    @available(iOS 13.0, *)
    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    @available(iOS 13.0, *)
    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }

}
