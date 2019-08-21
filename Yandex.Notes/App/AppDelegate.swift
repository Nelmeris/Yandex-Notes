//
//  AppDelegate.swift
//  Yandex.Notes
//
//  Created by Artem Kufaev on 02/07/2019.
//  Copyright © 2019 Artem Kufaev. All rights reserved.
//

import UIKit
import CocoaLumberjack
import CoreData

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    
    let mainStoryboardName = "Main"
    
    func instanceRootViewController() -> UIViewController {
        let storyboard = UIStoryboard(name: mainStoryboardName, bundle: nil)
        guard let navController = storyboard.instantiateInitialViewController() as? UINavigationController,
            let rootViewController = navController.topViewController as? NoteTableViewController else { fatalError() }
        
        setMergeContextAndBackgroundContextChangesNotification()
        
        rootViewController.context = persistentContainer.viewContext
        rootViewController.backgroundContext = persistentContainer.newBackgroundContext()
        
        return navController
    }

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        window = UIWindow(frame: UIScreen.main.bounds)
        guard let window = window else { fatalError() }
        
        BaseDBOperation.queue.maxConcurrentOperationCount = 1
        
        window.rootViewController = instanceRootViewController()
        window.makeKeyAndVisible()
        
        #if DEBUG
        
        UserDefaults.standard.removeObject(forKey: "no_connection_timer")
        
//        for _ in 1...15 {
//            let note = Note(title: "Some title", content: "Some content", importance: .usual)
//            let saveNote = SaveNoteOperation(note: note, context: persistentContainer.viewContext, backendQueue: BaseBackendOperation.queue, dbQueue: BaseDBOperation.queue)
//            BaseUIOperation.queue.addOperation(saveNote)
//        }
        
        #endif
        
        return true
    }
    
    func setMergeContextAndBackgroundContextChangesNotification() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(managedObjectContextDidSave(notification:)),
                                               name: NSNotification.Name.NSManagedObjectContextDidSave,
                                               object: persistentContainer.viewContext)
    }
    
    @objc func managedObjectContextDidSave(notification: Notification) {
        let context = notification.object as! NSManagedObjectContext
        context.perform {
            context.mergeChanges(fromContextDidSave: notification)
        }
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }
    
    // MARK: - Core Data stack
    
    lazy var persistentContainer: NSPersistentContainer = {
        /*
         The persistent container for the application. This implementation
         creates and returns a container, having loaded the store for the
         application to it. This property is optional since there are legitimate
         error conditions that could cause the creation of the store to fail.
         */
        let container = NSPersistentContainer(name: "Notes")
        container.loadPersistentStores { (storeDescription, error) in
            if let error = error as NSError? {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                
                /*
                 Typical reasons for an error here include:
                 * The parent directory does not exist, cannot be created, or disallows writing.
                 * The persistent store is not accessible, due to permissions or data protection when the device is locked.
                 * The device is out of space.
                 * The store could not be migrated to the current model version.
                 Check the error message to determine what the actual problem was.
                 */
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        }
        return container
    }()
    
    // MARK: - Core Data Saving support
    
    func saveContext () {
        let context = persistentContainer.viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nserror = error as NSError
                fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
            }
        }
    }

}

