package com.bkm.bexflutter

import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result

class BexFlutterPlugin : FlutterPlugin, MethodCallHandler, ActivityAware {
  private lateinit var channel: MethodChannel
  private var activityBinding: ActivityPluginBinding? = null
  private val bridge = BexFullSdkBridge()

  override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
    channel = MethodChannel(binding.binaryMessenger, "com.bkm.bex/full_sdk")
    channel.setMethodCallHandler(this)
    bridge.attach(binding.applicationContext) { activityBinding?.activity }
  }

  override fun onMethodCall(call: MethodCall, result: Result) {
    when (call.method) {
      "initialize" -> {
        @Suppress("UNCHECKED_CAST")
        val config = call.arguments as? Map<String, Any?> ?: emptyMap()
        bridge.initialize(config, result)
      }
      "pay" -> {
        @Suppress("UNCHECKED_CAST")
        val args = call.arguments as? Map<String, Any?> ?: emptyMap()
        @Suppress("UNCHECKED_CAST")
        val payment = args["payment"] as? Map<String, Any?> ?: emptyMap()
        @Suppress("UNCHECKED_CAST")
        val options = args["options"] as? Map<String, Any?> ?: emptyMap()
        bridge.pay(payment, options, result)
      }
      "selectCard" -> {
        @Suppress("UNCHECKED_CAST")
        val options = call.arguments as? Map<String, Any?> ?: emptyMap()
        bridge.selectCard(options, result)
      }
      else -> result.notImplemented()
    }
  }

  override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
    channel.setMethodCallHandler(null)
  }

  override fun onAttachedToActivity(binding: ActivityPluginBinding) {
    activityBinding = binding
  }

  override fun onDetachedFromActivityForConfigChanges() {
    activityBinding = null
  }

  override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
    activityBinding = binding
  }

  override fun onDetachedFromActivity() {
    activityBinding = null
  }
}
