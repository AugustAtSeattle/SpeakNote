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
        _ = DatabaseManager.shared
        testOPENAI()
        return true
    }
    
    func getOpenAIAPIKey() -> String? {
        if let path = Bundle.main.path(forResource: "Info", ofType: "plist"),
           let myDict = NSDictionary(contentsOfFile: path),
           let apiKey = myDict["OPENAI API Key"] as? String {
            return apiKey
        } else {
            return nil
        }
    }
    
    func testOPENAI() {
        guard let key = getOpenAIAPIKey() else {
            return
        }
        
        let openAI = OpenAISwift(config: .makeDefaultOpenAI(apiKey: key))
        
        Task {
            do {
                
                let chat: [ChatMessage] = [
                    ChatMessage(role: .system, content: "You are a helpful assistant."),
                    ChatMessage(role: .user, content: "Who won the world series in 2020?"),
                    ChatMessage(role: .assistant, content: "The Los Angeles Dodgers won the World Series in 2020."),
                    ChatMessage(role: .user, content: "Where was it played?")
                ]
                            
                let result = try await openAI.sendChat(with: chat)
                
                print(result.choices?.first?.message ?? "unknown")
            } catch {
                print(error)
            }
        }
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

