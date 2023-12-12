//
//  AppDelegate.swift
//  SpeakNote
//
//  Created by Sailor on 11/27/23.
//

import UIKit
import OpenAISwift

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        let db = DatabaseManager.shared
//        db.insertSampleNotesIfEmpty()

        let notes = db.fetchNotes()
        print(notes)
        let insertQuery = """
            INSERT INTO notes (subject, details, createDate, deadline, category, status)
            VALUES ('Get Birthday Cake', 'Get a birthday cake before 5 PM', CURRENT_TIMESTAMP, DATE('now'), 'Personal', 'Pending');
        """

//        db.executeQuery(insertQuery)
        
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

