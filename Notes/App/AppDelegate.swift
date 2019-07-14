//
//  AppDelegate.swift
//  Notes
//
//  Created by Artem Kufaev on 02/07/2019.
//  Copyright © 2019 Artem Kufaev. All rights reserved.
//

import UIKit
import CocoaLumberjack

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func printJSON(json: [String: Any]) {
        for (key, value) in json {
            if let newJson = value as? [String: Any] {
                print("'\(key)' [")
                printJSON(json: newJson)
                print("]")
            } else {
                print("'\(key)': \(value)")
            }
        }
    }

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        #if DEBUG
        
        let notebook = FileNotebook()
        notebook.loadFromFile()
        
        if notebook.notes.count == 0 {
            
            var note = Note(title: "Заметка для демо 1", content: "Какой-то контент",
                            color: .black, importance: .critical, destructionDate: Date())
            notebook.add(note)
            
            note = Note(title: "Заметка для демо 2", content: "Lorem Ipsum is simply dummy text of the printing and typesetting industry. Lorem Ipsum has been the industry's standard dummy text ever since the 1500s, when an unknown printer took a galley of type and scrambled it to make",
                        color: .yellow, importance: .usual, destructionDate: Date())
            notebook.add(note)
            
            note = Note(title: "Заметка для демо 3", content: "Lorem Ipsum is simply dummy text of the printing and typesetting",
                        color: .white, importance: .usual)
            notebook.add(note)
            
            note = Note(title: "Заметка для демо 4", content: "Lorem Ipsum is simply dummy text of the printing and typesetting industry. Lorem Ipsum has been the industry's standard dummy text ever since the 1500s, when an unknown printer took a galley of type and scrambled it to make a type specimen book. It has survived not only five centuries, but also the leap into electronic typesetting, remaining essentially unchanged. It was popularised in the 1960s with the release of Letraset sheets containing Lorem Ipsum passages, and more recently with desktop publishing software like Aldus PageMaker including versions of Lore",
                        color: .red, importance: .usual)
            notebook.add(note)
            
            notebook.saveToFile()
        }
        
        #elseif DEMO
        
        var note = Note(title: "Заметка для демо 1", content: "Какой-то контент",
                        color: .black, importance: .critical, destructionDate: Date())
        let notebook = FileNotebook()
        notebook.add(note)
        
        note = Note(title: "Заметка для демо 2", content: "Какой-то контент 2",
                    color: .yellow, importance: .usual, destructionDate: Date())
        notebook.add(note)
        DDLogDebug("Созданы демонстрационные заметки")
        
        #endif
        
        return true
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


}

