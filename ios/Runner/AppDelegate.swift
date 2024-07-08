import Foundation
import UIKit
import Flutter
import Intents

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
  var flutterChannel: FlutterMethodChannel?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)

    let controller = window?.rootViewController as! FlutterViewController
    flutterChannel = FlutterMethodChannel(name: "com.example.instagramCloneFlutter/commands", binaryMessenger: controller.binaryMessenger)

    INPreferences.requestSiriAuthorization { status in
      if status == .authorized {
        self.donateIntents()
      }
    }

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func application(_ application: UIApplication, handlerFor intent: INIntent) -> Any? {
    switch intent {
    case is SwipeUpIntent:
      return SwipeUpIntentHandler(flutterChannel: flutterChannel)
    case is SwipeDownIntent:
      return SwipeDownIntentHandler(flutterChannel: flutterChannel)
    default:
      return nil
    }
  }

  private func donateIntents() {
    let swipeUpIntent = SwipeUpIntent()
    swipeUpIntent.suggestedInvocationPhrase = "Swipe up"

    let interaction = INInteraction(intent: swipeUpIntent, response: nil)
    interaction.donate { error in
      if let error = error {
        print("Failed to donate interaction: \(error)")
      } else {
        print("Successfully donated interaction")
      }
    }

    let swipeDownIntent = SwipeDownIntent()
    swipeDownIntent.suggestedInvocationPhrase = "Swipe down"

    let interactionDown = INInteraction(intent: swipeDownIntent, response: nil)
    interactionDown.donate { error in
      if let error = error {
        print("Failed to donate interaction: \(error)")
      } else {
        print("Successfully donated interaction")
      }
    }
  }
}
