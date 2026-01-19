import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)

    // Register Apple Intelligence plugin for on-device AI
    let controller = window?.rootViewController as! FlutterViewController
    let channel = FlutterMethodChannel(
      name: "com.triplystays.app/apple_intelligence",
      binaryMessenger: controller.binaryMessenger
    )

    channel.setMethodCallHandler { [weak self] (call, result) in
      self?.handleAppleIntelligenceCall(call: call, result: result)
    }

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  private func handleAppleIntelligenceCall(call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "isAvailable":
      // Apple Intelligence requires iOS 18+
      if #available(iOS 18.0, *) {
        // Apple Intelligence API not yet publicly available
        result(false)
      } else {
        result(false)
      }

    case "generateResponse":
      // Placeholder - Apple Intelligence API not yet available
      result("Apple Intelligence is not yet available. Please use the cloud-based AI assistant.")

    case "parseStructuredResponse":
      // Placeholder - returns empty dictionary
      result([String: Any]())

    default:
      result(FlutterMethodNotImplemented)
    }
  }
}
