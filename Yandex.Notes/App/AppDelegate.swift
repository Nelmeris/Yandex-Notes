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

let commonQueue = OperationQueue.main

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

//    func printJSON(json: Note.JSON) {
//        for (key, value) in json {
//            if let newJson = value as? [String: Any] {
//                print("'\(key)' [")
//                printJSON(json: newJson)
//                print("]")
//            } else {
//                print("'\(key)': \(value)")
//            }
//        }
//    }
    
//    private func initNotebook(context: NSManagedObjectContext, backgroundContext: NSManagedObjectContext) {
//        var note = Note(title: "Заметка для демо 1", content: "Какой-то контент",
//                        color: .black, importance: .critical, destructionDate: Date())
//
//        var saveNoteOperation = SaveNoteOperation(
//            note: note,
//            context: backgroundContext,
//            mainQueue: commonQueue,
//            backendQueue: backendQueue,
//            dbQueue: dbQueue
//        )
//        commonQueue.addOperation(saveNoteOperation)
//
//        note = Note(title: "Заметка для демо 2", content: "Lorem Ipsum is simply dummy text of the printing and typesetting industry. Lorem Ipsum has been the industry's standard dummy text ever since the 1500s, when an unknown printer took a galley of type and scrambled it to make",
//                    color: .yellow, importance: .usual, destructionDate: Date())
//        saveNoteOperation = SaveNoteOperation(
//            note: note,
//            context: backgroundContext,
//            mainQueue: commonQueue,
//            backendQueue: backendQueue,
//            dbQueue: dbQueue
//        )
//        commonQueue.addOperation(saveNoteOperation)
//
//        note = Note(title: "Заметка для демо 3", content: "Lorem Ipsum is simply dummy text of the printing and typesetting",
//                    color: .white, importance: .usual)
//        saveNoteOperation = SaveNoteOperation(
//            note: note,
//            context: backgroundContext,
//            mainQueue: commonQueue,
//            backendQueue: backendQueue,
//            dbQueue: dbQueue
//        )
//        commonQueue.addOperation(saveNoteOperation)
//
//        note = Note(title: "Заметка для демо 4", content: "Lorem Ipsum is simply dummy text of the printing and typesetting industry. Lorem Ipsum has been the industry's standard dummy text ever since the 1500s, when an unknown printer took a galley of type and scrambled it to make a type specimen book. It has survived not only five centuries, but also the leap into electronic typesetting, remaining essentially unchanged. It was popularised in the 1960s with the release of Letraset sheets containing Lorem Ipsum passages, and more recently with desktop publishing software like Aldus PageMaker including versions of Lore",
//                    color: .red, importance: .usual)
//        saveNoteOperation = SaveNoteOperation(
//            note: note,
//            context: backgroundContext,
//            mainQueue: commonQueue,
//            backendQueue: backendQueue,
//            dbQueue: dbQueue
//        )
//        commonQueue.addOperation(saveNoteOperation)
//
//        saveNoteOperation.completionBlock = {
//            UserDefaults.standard.set(true, forKey: "INITED")
//        }
//    }
    
    let mainStoryboardName = "Main"

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        window = UIWindow(frame: UIScreen.main.bounds)
        guard let window = window else { fatalError() }
        
        UserDefaults.standard.removeObject(forKey: "no_connection_timer")
        
        let storyboard = UIStoryboard(name: mainStoryboardName, bundle: nil)
        guard let navController = storyboard.instantiateInitialViewController() as? UINavigationController,
            let rootViewController = navController.topViewController as? NoteTableViewController else { fatalError() }
        
        let context = persistentContainer.viewContext
        let backgroundContext = persistentContainer.newBackgroundContext()
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(managedObjectContextDidSave(notification:)),
                                               name: NSNotification.Name.NSManagedObjectContextDidSave,
                                               object: context)
        
        rootViewController.context = persistentContainer.viewContext
        rootViewController.backgroundContext = backgroundContext
        
        window.rootViewController = navController
        window.makeKeyAndVisible()
        
        #if DEBUG
        
//        if !UserDefaults.standard.bool(forKey: "INITED") {
//            initNotebook(context: context, backgroundContext: backgroundContext)
//        }
        
        #endif
        
        return true
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

