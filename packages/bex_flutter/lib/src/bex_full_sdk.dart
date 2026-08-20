import 'dart:math';

import 'package:bex_flutter/src/bex_error.dart';
import 'package:bex_flutter/src/bex_flutter_platform.dart';
import 'package:bex_flutter/src/types.dart';
import 'package:flutter/services.dart';

String createTransactionId() {
  final random = Random.secure();
  String hex(int length) {
    final buffer = StringBuffer();
    for (var i = 0; i < length; i++) {
      buffer.write(random.nextInt(16).toRadixString(16));
    }
    return buffer.toString();
  }

  // RFC4122 version-4 UUID.
  final variant = (random.nextInt(4) + 8).toRadixString(16);
  return '${hex(8)}-${hex(4)}-4${hex(3)}-$variant${hex(3)}-${hex(12)}';
}

void assertInitializeConfig(InitializeConfig config) {
  if (config.authToken.trim().isEmpty) {
    throw BexError(BexErrorCode.invalidArgument, 'authToken is required.');
  }
  if (config.merchantId.trim().isEmpty) {
    throw BexError(BexErrorCode.invalidArgument, 'merchantId is required.');
  }
  if (config.merchantUserId.trim().isEmpty) {
    throw BexError(BexErrorCode.invalidArgument, 'merchantUserId is required.');
  }
  if (config.gsmNo.trim().isEmpty) {
    throw BexError(BexErrorCode.invalidArgument, 'gsmNo is required.');
  }
}

void assertPaymentData(PaymentData payment) {
  if (payment.amount.isNaN) {
    throw BexError(BexErrorCode.invalidArgument, 'amount must be a number.');
  }
  if (payment.orderId.trim().isEmpty) {
    throw BexError(BexErrorCode.invalidArgument, 'orderId is required.');
  }
  if (payment.installmentCount < 1) {
    throw BexError(
      BexErrorCode.invalidArgument,
      'installmentCount must be a positive integer.',
    );
  }
}

Future<T> withPlatformError<T>(Future<T> Function() operation) async {
  try {
    return await operation();
  } on BexError {
    rethrow;
  } on PlatformException catch (error) {
    throw BexError.fromPlatform(error);
  } catch (error) {
    throw BexError.fromPlatform(error);
  }
}

/// Public facade mirroring the React Native `BexFullSdk` API.
class BexFullSdk {
  BexFullSdk._();

  static Future<InitializeResult> initialize(InitializeConfig config) {
    assertInitializeConfig(config);
    return withPlatformError(() async {
      final raw = await BexFlutterPlatform.instance.initialize(config.toMap());
      return InitializeResult.fromMap(raw);
    });
  }

  static Future<PayResult> pay(
    PaymentData payment, [
    FlowOptions options = const FlowOptions(),
  ]) {
    assertPaymentData(payment);
    final payload = PaymentData(
      amount: payment.amount,
      orderId: payment.orderId,
      security: payment.security,
      installmentCount: payment.installmentCount,
      currency: (payment.currency?.trim().isNotEmpty ?? false)
          ? payment.currency!.trim()
          : 'TRY',
      transactionType: payment.transactionType ?? TransactionType.sale,
      transactionId: (payment.transactionId?.trim().isNotEmpty ?? false)
          ? payment.transactionId!.trim()
          : createTransactionId(),
      transactionDate: (payment.transactionDate?.trim().isNotEmpty ?? false)
          ? payment.transactionDate!.trim()
          : DateTime.now().millisecondsSinceEpoch.toString(),
      successUrl: payment.successUrl ?? '',
      failUrl: payment.failUrl ?? '',
      extras: payment.extras,
    );

    final flow = FlowOptions(
      style: options.style ?? PresentationStyle.fullScreen,
      theme: options.theme,
      extras: options.extras,
    );

    return withPlatformError(() async {
      final raw = await BexFlutterPlatform.instance.pay(
        payload.toMap(),
        flow.toMap(),
      );
      return PayResult.fromMap(raw);
    });
  }

  /// Accepts either [PaymentData] or [FlowOptions] as the first argument,
  /// matching the React Native overload.
  static Future<SelectCardResult> selectCard([
    Object? paymentOrOptions,
    FlowOptions options = const FlowOptions(),
  ]) {
    final looksLikePayment = paymentOrOptions is PaymentData ||
        (paymentOrOptions is Map &&
            (paymentOrOptions.containsKey('amount') ||
                paymentOrOptions.containsKey('orderId') ||
                paymentOrOptions.containsKey('security') ||
                paymentOrOptions.containsKey('installmentCount')));

    PaymentData? payment;
    FlowOptions flowOptions = options;

    if (looksLikePayment) {
      if (paymentOrOptions is PaymentData) {
        payment = paymentOrOptions;
      }
    } else if (paymentOrOptions is FlowOptions) {
      flowOptions = paymentOrOptions;
    }

    final now = DateTime.now().millisecondsSinceEpoch;
    final payload = PaymentData(
      amount: payment?.amount ?? 100,
      orderId: (payment?.orderId.trim().isNotEmpty ?? false)
          ? payment!.orderId.trim()
          : 'DEMO-$now',
      security: payment?.security ?? PaymentSecurity.none,
      installmentCount: payment?.installmentCount ?? 1,
      currency: (payment?.currency?.trim().isNotEmpty ?? false)
          ? payment!.currency!.trim()
          : 'TRY',
      transactionType: payment?.transactionType ?? TransactionType.sale,
      transactionId: (payment?.transactionId?.trim().isNotEmpty ?? false)
          ? payment!.transactionId!.trim()
          : createTransactionId(),
      transactionDate: (payment?.transactionDate?.trim().isNotEmpty ?? false)
          ? payment!.transactionDate!.trim()
          : now.toString(),
      successUrl: payment?.successUrl ??
          'https://trcuzdan-dev.bkmtest.com.tr/sdk/demo/success',
      failUrl: payment?.failUrl ??
          'https://trcuzdan-dev.bkmtest.com.tr/sdk/demo/fail',
      extras: payment?.extras,
    );

    final flow = FlowOptions(
      style: flowOptions.style ?? PresentationStyle.fullScreen,
      theme: flowOptions.theme,
      extras: flowOptions.extras,
    );

    return withPlatformError(() async {
      final raw = await BexFlutterPlatform.instance.selectCard({
        ...flow.toMap(),
        'payment': payload.toMap(),
      });
      return SelectCardResult.fromMap(raw);
    });
  }
}
