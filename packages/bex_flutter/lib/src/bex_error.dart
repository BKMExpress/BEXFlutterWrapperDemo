import 'package:bex_flutter/src/types.dart';
import 'package:flutter/services.dart';

class BexError implements Exception {
  BexError(
    this.code,
    this.message, {
    this.title,
    this.nativeCode,
    this.reason,
  });

  final BexErrorCode code;
  final String message;
  final String? title;
  final int? nativeCode;
  final String? reason;

  static BexError fromPlatform(Object error) {
    if (error is BexError) {
      return error;
    }

    if (error is PlatformException) {
      final details = error.details;
      Map<Object?, Object?>? detailMap;
      if (details is Map) {
        detailMap = Map<Object?, Object?>.from(details);
      }

      final code = BexErrorCodeWire.fromWire(
        detailMap?['code']?.toString() ?? error.code,
      );
      final message = detailMap?['message']?.toString() ??
          error.message ??
          'An unknown BEX SDK error occurred.';

      return BexError(
        code,
        message,
        title: detailMap?['title']?.toString(),
        nativeCode: (detailMap?['nativeCode'] as num?)?.toInt(),
        reason: detailMap?['reason']?.toString(),
      );
    }

    if (error is String) {
      return BexError(BexErrorCode.unknown, error);
    }

    return BexError(
      BexErrorCode.unknown,
      'An unknown BEX SDK error occurred.',
    );
  }

  Map<String, dynamic> toJson() => {
        'error': true,
        'code': code.wireName,
        'message': message,
        if (title != null) 'title': title,
        if (nativeCode != null) 'nativeCode': nativeCode,
        if (reason != null) 'reason': reason,
      };

  @override
  String toString() => 'BexError($code): $message';
}
