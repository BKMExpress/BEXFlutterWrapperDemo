import Flutter
import UIKit

public class BexFlutterPlugin: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(
      name: "com.bkm.bex/full_sdk",
      binaryMessenger: registrar.messenger()
    )
    let instance = BexFlutterPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "initialize":
      let config = (call.arguments as? [String: Any]) ?? [:]
      BexFullSdkBridge.shared.initialize(config, result: result)
    case "pay":
      let args = (call.arguments as? [String: Any]) ?? [:]
      let payment = (args["payment"] as? [String: Any]) ?? [:]
      let options = (args["options"] as? [String: Any]) ?? [:]
      BexFullSdkBridge.shared.pay(payment, options: options, result: result)
    case "selectCard":
      let options = (call.arguments as? [String: Any]) ?? [:]
      BexFullSdkBridge.shared.selectCard(options, result: result)
    default:
      result(FlutterMethodNotImplemented)
    }
  }
}
