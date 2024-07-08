//
//  IntentHandler.swift
//  TikTokIntents
//
//  Created by Swapnamoy Bhowmick on 7/5/24.
//
import Intents
import Flutter
import Foundation

class IntentHandler: INExtension {
    override func handler(for intent: INIntent) -> Any {
        switch intent {
        case is SwipeUpIntent:
            return SwipeUpIntentHandler()
        case is SwipeDownIntent:
            return SwipeDownIntentHandler()
        default:
            fatalError("Unhandled Intent error : \(intent)")
        }
    }
}

class SwipeUpIntentHandler: NSObject, SwipeUpIntentHandling {
    
    func handle(intent: SwipeUpIntent, completion: @escaping (SwipeUpIntentResponse) -> Void) {
        // Perform the action for the swipe up intent
        // Ensure this operation runs on the main thread
        DispatchQueue.main.async {
            guard let controller = UIApplication.shared.keyWindow?.rootViewController as? FlutterViewController else {
                completion(SwipeUpIntentResponse(code: .failure, userActivity: nil))
                return
            }
            let channel = FlutterMethodChannel(name: "com.example.instagramCloneFlutter/commands", binaryMessenger: controller.binaryMessenger)
            channel.invokeMethod("swipeUp", arguments: nil) { result in
                if let error = result as? FlutterError {
                    // Handle the error
                    completion(SwipeUpIntentResponse(code: .failure, userActivity: nil))
                } else {
                    // Handle success
                    completion(SwipeUpIntentResponse.success())
                }
            }
        }
    }
}

class SwipeDownIntentHandler: NSObject, SwipeDownIntentHandling {
    
    func handle(intent: SwipeDownIntent, completion: @escaping (SwipeDownIntentResponse) -> Void) {
        // Perform the action for the swipe Down intent
        // Ensure this operation runs on the main thread
        DispatchQueue.main.async {
            guard let controller = UIApplication.shared.keyWindow?.rootViewController as? FlutterViewController else {
                completion(SwipeDownIntentResponse(code: .failure, userActivity: nil))
                return
            }
            let channel = FlutterMethodChannel(name: "com.example.instagramCloneFlutter/commands", binaryMessenger: controller.binaryMessenger)
            channel.invokeMethod("swipeDown", arguments: nil) { result in
                if let error = result as? FlutterError {
                    // Handle the error
                    completion(SwipeDownIntentResponse(code: .failure, userActivity: nil))
                } else {
                    // Handle success
                    completion(SwipeDownIntentResponse.success())
                }
            }
        }
    }
}

