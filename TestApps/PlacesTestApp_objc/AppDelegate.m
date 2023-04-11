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

#import "AppDelegate.h"
@import AEPCore;
@import AEPPlaces;
@import AEPAssurance;
@import AEPServices;

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    
    [AEPMobileCore setLogLevel:AEPLogLevelTrace];
    
    // steve-places in Adobe Benedick Corp: launch-EN459260fc579a4dcbb2d1743947e65f09-development
    [AEPMobileCore configureWithAppId:@"launch-EN459260fc579a4dcbb2d1743947e65f09-development"];
    
    [AEPMobileCore registerExtensions:@[AEPMobilePlaces.class, AEPMobileAssurance.class] completion:^{
        // Griffon Session - AEPPlaces_objc in Adobe Benedick Corp
        [AEPMobileAssurance startSessionWithUrl:[NSURL URLWithString:@"aepplaces://?adb_validation_sessionid=45028228-fc99-4865-87cb-99351de0c064"]];
        NSLog(@"places version: %@", [AEPMobilePlaces extensionVersion]);
    }];
        
    return YES;
}


#pragma mark - UISceneSession lifecycle


- (UISceneConfiguration *)application:(UIApplication *)application configurationForConnectingSceneSession:(UISceneSession *)connectingSceneSession options:(UISceneConnectionOptions *)options  API_AVAILABLE(ios(13.0)){
    // Called when a new scene session is being created.
    // Use this method to select a configuration to create the new scene with.
    return [[UISceneConfiguration alloc] initWithName:@"Default Configuration" sessionRole:connectingSceneSession.role];
}


- (void)application:(UIApplication *)application didDiscardSceneSessions:(NSSet<UISceneSession *> *)sceneSessions  API_AVAILABLE(ios(13.0)){
    // Called when the user discards a scene session.
    // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
    // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
}


@end
