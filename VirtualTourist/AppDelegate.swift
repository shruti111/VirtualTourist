//
//  AppDelegate.swift
//  VirtualTourist
//
//  Created by Shruti Pawar on 08/05/15.
//  Copyright (c) 2015 ShapeMyApp Software Solutions Pvt. Ltd. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    
    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        // Override point for customization after application launch.
       
        // Show core data error and terminate the app
        self.showFatalCoreDataNotifications()
        return true
    }

    func applicationWillResignActive(application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }
    
    //MARK:- Core Data Error 
    
    // Core data error is displayed here in Alert - This error is posted from CoreDataStackManager.swift
    
    // Notification to post and listen from AppDelegate
    
    let coreDataOperationDidFailNotification = "coreDataOperationDidFailNotification"
    
    //Call this function from CoreDataStackManager when error is there
    func fatalCoreDataError(error: NSError?) {
        
        if let fatalError = error {
            println("Fatal Core Data error: \(fatalError), \(fatalError.userInfo)")
        }
        
        NSNotificationCenter.defaultCenter().postNotificationName(coreDataOperationDidFailNotification, object: error)
    }
    
    // Show alert by listening to Notification
    func showFatalCoreDataNotifications() {
        
        NSNotificationCenter.defaultCenter().addObserverForName(coreDataOperationDidFailNotification, object: nil, queue: NSOperationQueue.mainQueue(), usingBlock: {
            notification in
            
            let alert = UIAlertController(title: "Application Error",
                message: "There was a fatal error in the app. \n\n"
                    + "Press OK to terminate the app. App cannot continue. We are sorry for this inconvenience.",
                preferredStyle: .Alert)
            
            let action = UIAlertAction(title: "OK", style: .Default) { _ in
                
                // Terminate the app after message is displayed.
                abort()
            }
            
            alert.addAction(action)
            
            self.viewControllerForShowingAlert().presentViewController(alert, animated: true, completion: nil)
        })
    }
    
    // Show Alert view controller on any of the view controller which is currently displayed to the user.
    func viewControllerForShowingAlert() -> UIViewController {
        
        let rootViewController = self.window!.rootViewController!
        
        if let displayedViewController = rootViewController.presentedViewController {
            return displayedViewController
        } else {
            return rootViewController
        }
    }
    
}

