import 'dart:convert';

import 'package:bex_flutter/bex_flutter.dart';
import 'package:flutter/material.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const BexDemoApp());
}

class BexDemoApp extends StatelessWidget {
  const BexDemoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BEX Flutter Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0F6E56),
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFF7F4EF),
        useMaterial3: true,
      ),
      home: const DemoHomePage(),
    );
  }
}

class DemoHomePage extends StatefulWidget {
  const DemoHomePage({super.key});

  @override
  State<DemoHomePage> createState() => _DemoHomePageState();
}

class _DemoHomePageState extends State<DemoHomePage> {
  static const _environments = BexEnvironment.values;
  static const _securities = PaymentSecurity.values;
  static const _styles = PresentationStyle.values;
  static const _transactionTypes = [
    TransactionType.sale,
    TransactionType.preAuth,
  ];

  final _authToken = TextEditingController();
  final _merchantId = TextEditingController();
  final _gsmNo = TextEditingController();
  final _merchantUserId = TextEditingController();
  final _amount = TextEditingController();
  final _orderId = TextEditingController();

  BexEnvironment _environment = BexEnvironment.dev;
  PaymentSecurity _security = PaymentSecurity.none;
  PresentationStyle _style = PresentationStyle.fullScreen;
  TransactionType _transactionType = TransactionType.sale;
  bool _busy = false;
  bool _initialized = false;
  String _resultText = 'Ready.';

  @override
  void dispose() {
    _authToken.dispose();
    _merchantId.dispose();
    _gsmNo.dispose();
    _merchantUserId.dispose();
    _amount.dispose();
    _orderId.dispose();
    super.dispose();
  }

  void _showResult(Object value) {
    setState(() {
      if (value is String) {
        _resultText = value;
      } else {
        _resultText = const JsonEncoder.withIndent('  ').convert(value);
      }
    });
  }

  Future<void> _run(Future<Object?> Function() action) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final result = await action();
      if (result is PayResult) {
        _showResult(result.toJson());
      } else if (result is SelectCardResult) {
        _showResult(result.toJson());
      } else if (result is InitializeResult) {
        _showResult(result.toJson());
      } else {
        _showResult(result ?? 'null');
      }
    } catch (error) {
      final bexError = BexError.fromPlatform(error);
      _showResult(bexError.toJson());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final canSubmit = !_busy;

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const Text(
              'BEX Flutter Demo',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1C1A17),
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Consumes bex_flutter as a path dependency.',
              style: TextStyle(fontSize: 14, color: Color(0xFF5C564C)),
            ),
            const SizedBox(height: 16),
            _Field(label: 'Auth token', controller: _authToken, maxLines: 4),
            _Field(label: 'Merchant ID', controller: _merchantId),
            _Field(label: 'GSM', controller: _gsmNo),
            _Field(label: 'Merchant user ID', controller: _merchantUserId),
            _Field(label: 'Amount', controller: _amount),
            _Field(label: 'Order ID', controller: _orderId),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _CycleChip(
                  label: 'Env',
                  value: _environment.name,
                  onTap: () {
                    final index = _environments.indexOf(_environment);
                    setState(() {
                      _environment =
                          _environments[(index + 1) % _environments.length];
                    });
                  },
                ),
                _CycleChip(
                  label: 'Security',
                  value: _security.name,
                  onTap: () {
                    final index = _securities.indexOf(_security);
                    setState(() {
                      _security =
                          _securities[(index + 1) % _securities.length];
                    });
                  },
                ),
                _CycleChip(
                  label: 'Style',
                  value: _style.name,
                  onTap: () {
                    final index = _styles.indexOf(_style);
                    setState(() {
                      _style = _styles[(index + 1) % _styles.length];
                    });
                  },
                ),
                _CycleChip(
                  label: 'Txn',
                  value: _transactionTypeLabel(_transactionType),
                  onTap: () {
                    final index = _transactionTypes.indexOf(_transactionType);
                    setState(() {
                      _transactionType = _transactionTypes[
                          (index + 1) % _transactionTypes.length];
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _ActionButton(
                  label: 'Initialize',
                  enabled: canSubmit,
                  onPressed: () => _run(() async {
                    final result = await BexFullSdk.initialize(
                      InitializeConfig(
                        authToken: _authToken.text,
                        merchantId: _merchantId.text,
                        merchantUserId: _merchantUserId.text,
                        gsmNo: _gsmNo.text,
                        environment: _environment,
                        currencyCode: 'TRY',
                      ),
                    );
                    setState(() => _initialized = true);
                    return result;
                  }),
                ),
                _ActionButton(
                  label: 'Pay',
                  enabled: canSubmit && _initialized,
                  onPressed: () => _run(
                    () => BexFullSdk.pay(
                      PaymentData(
                        amount: double.tryParse(_amount.text) ?? double.nan,
                        orderId: _orderId.text,
                        security: _security,
                        installmentCount: 1,
                        currency: 'TRY',
                        transactionType: _transactionType,
                        successUrl:
                            'https://trcuzdan-dev.bkmtest.com.tr/sdk/demo/success',
                        failUrl:
                            'https://trcuzdan-dev.bkmtest.com.tr/sdk/demo/fail',
                      ),
                      FlowOptions(style: _style),
                    ),
                  ),
                ),
                _ActionButton(
                  label: 'Select card',
                  enabled: canSubmit && _initialized,
                  onPressed: () => _run(
                    () => BexFullSdk.selectCard(
                      PaymentData(
                        amount: double.tryParse(_amount.text) ?? double.nan,
                        orderId: _orderId.text,
                        security: _security,
                        installmentCount: 1,
                        currency: 'TRY',
                        transactionType: _transactionType,
                        successUrl:
                            'https://trcuzdan-dev.bkmtest.com.tr/sdk/demo/success',
                        failUrl:
                            'https://trcuzdan-dev.bkmtest.com.tr/sdk/demo/fail',
                      ),
                      FlowOptions(style: _style),
                    ),
                  ),
                ),
              ],
            ),
            if (_busy) ...[
              const SizedBox(height: 12),
              const Center(child: CircularProgressIndicator()),
            ],
            const SizedBox(height: 16),
            const Text(
              'Result',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Color(0xFF3F3A34),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFDF9),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFD9D2C7)),
              ),
              child: Text(
                _resultText,
                style: const TextStyle(
                  fontFamily: 'Courier',
                  fontSize: 12,
                  color: Color(0xFF1C1A17),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _transactionTypeLabel(TransactionType type) {
    return switch (type) {
      TransactionType.sale => 'SALE',
      TransactionType.preAuth => 'PRE_AUTH',
      TransactionType.recurring => 'RECURRING',
    };
  }
}

class _Field extends StatelessWidget {
  const _Field({
    required this.label,
    required this.controller,
    this.maxLines = 1,
  });

  final String label;
  final TextEditingController controller;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF3F3A34),
            ),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: controller,
            maxLines: maxLines,
            autocorrect: false,
            enableSuggestions: false,
            decoration: InputDecoration(
              filled: true,
              fillColor: const Color(0xFFFFFDF9),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFFD9D2C7)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFFD9D2C7)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CycleChip extends StatelessWidget {
  const _CycleChip({
    required this.label,
    required this.value,
    required this.onTap,
  });

  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFE8E1D6),
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Text(
            '$label: $value',
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 13,
              color: Color(0xFF1C1A17),
            ),
          ),
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.onPressed,
    required this.enabled,
  });

  final String label;
  final VoidCallback onPressed;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1 : 0.45,
      child: FilledButton(
        onPressed: enabled ? onPressed : null,
        style: FilledButton.styleFrom(
          backgroundColor: const Color(0xFF0F6E56),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}
