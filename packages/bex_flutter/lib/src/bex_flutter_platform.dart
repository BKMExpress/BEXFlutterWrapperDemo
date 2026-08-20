import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

const MethodChannel _channel = MethodChannel('com.bkm.bex/full_sdk');

abstract class BexFlutterPlatform extends PlatformInterface {
  BexFlutterPlatform() : super(token: _token);

  static final Object _token = Object();

  static BexFlutterPlatform _instance = MethodChannelBexFlutter();

  static BexFlutterPlatform get instance => _instance;

  static set instance(BexFlutterPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<Map<Object?, Object?>> initialize(Map<String, dynamic> config);

  Future<Map<Object?, Object?>> pay(
    Map<String, dynamic> payment,
    Map<String, dynamic> options,
  );

  Future<Map<Object?, Object?>> selectCard(Map<String, dynamic> options);
}

class MethodChannelBexFlutter extends BexFlutterPlatform {
  @visibleForTesting
  MethodChannel get channel => _channel;

  @override
  Future<Map<Object?, Object?>> initialize(Map<String, dynamic> config) async {
    final result = await _channel.invokeMethod<dynamic>('initialize', config);
    return Map<Object?, Object?>.from(result as Map);
  }

  @override
  Future<Map<Object?, Object?>> pay(
    Map<String, dynamic> payment,
    Map<String, dynamic> options,
  ) async {
    final result = await _channel.invokeMethod<dynamic>('pay', {
      'payment': payment,
      'options': options,
    });
    return Map<Object?, Object?>.from(result as Map);
  }

  @override
  Future<Map<Object?, Object?>> selectCard(
    Map<String, dynamic> options,
  ) async {
    final result = await _channel.invokeMethod<dynamic>('selectCard', options);
    return Map<Object?, Object?>.from(result as Map);
  }
}
