enum BexEnvironment {
  dev,
  test,
  preprod,
  prod,
}

enum PaymentSecurity {
  tds,
  otp,
  none,
}

enum TransactionType {
  sale,
  preAuth,
  recurring,
}

enum PresentationStyle {
  sheet,
  fullScreen,
}

enum BexErrorCode {
  network,
  cancelled,
  unauthorized,
  api,
  session,
  encryption,
  server,
  unknown,
  notInitialized,
  alreadyInProgress,
  invalidArgument,
  noActivity,
}

extension BexErrorCodeWire on BexErrorCode {
  String get wireName => switch (this) {
        BexErrorCode.network => 'network',
        BexErrorCode.cancelled => 'cancelled',
        BexErrorCode.unauthorized => 'unauthorized',
        BexErrorCode.api => 'api',
        BexErrorCode.session => 'session',
        BexErrorCode.encryption => 'encryption',
        BexErrorCode.server => 'server',
        BexErrorCode.unknown => 'unknown',
        BexErrorCode.notInitialized => 'not_initialized',
        BexErrorCode.alreadyInProgress => 'already_in_progress',
        BexErrorCode.invalidArgument => 'invalid_argument',
        BexErrorCode.noActivity => 'no_activity',
      };

  static BexErrorCode fromWire(String? value) {
    switch (value) {
      case 'network':
        return BexErrorCode.network;
      case 'cancelled':
        return BexErrorCode.cancelled;
      case 'unauthorized':
        return BexErrorCode.unauthorized;
      case 'api':
        return BexErrorCode.api;
      case 'session':
        return BexErrorCode.session;
      case 'encryption':
        return BexErrorCode.encryption;
      case 'server':
        return BexErrorCode.server;
      case 'not_initialized':
        return BexErrorCode.notInitialized;
      case 'already_in_progress':
        return BexErrorCode.alreadyInProgress;
      case 'invalid_argument':
        return BexErrorCode.invalidArgument;
      case 'no_activity':
        return BexErrorCode.noActivity;
      default:
        return BexErrorCode.unknown;
    }
  }
}

class BexThemeColors {
  const BexThemeColors({
    this.primary,
    this.primaryVariant,
    this.background,
    this.surface,
    this.textPrimary,
    this.textSecondary,
    this.textOnPrimary,
    this.buttonPrimary,
    this.buttonPrimaryText,
    this.buttonSecondaryBorder,
    this.buttonSecondaryText,
    this.buttonDisabled,
    this.success,
    this.error,
    this.warning,
    this.border,
    this.divider,
    this.tint,
  });

  final String? primary;
  final String? primaryVariant;
  final String? background;
  final String? surface;
  final String? textPrimary;
  final String? textSecondary;
  final String? textOnPrimary;
  final String? buttonPrimary;
  final String? buttonPrimaryText;
  final String? buttonSecondaryBorder;
  final String? buttonSecondaryText;
  final String? buttonDisabled;
  final String? success;
  final String? error;
  final String? warning;
  final String? border;
  final String? divider;

  /// iOS tint color (falls back to primary when omitted).
  final String? tint;

  Map<String, dynamic> toMap() {
    return {
      if (primary != null) 'primary': primary,
      if (primaryVariant != null) 'primaryVariant': primaryVariant,
      if (background != null) 'background': background,
      if (surface != null) 'surface': surface,
      if (textPrimary != null) 'textPrimary': textPrimary,
      if (textSecondary != null) 'textSecondary': textSecondary,
      if (textOnPrimary != null) 'textOnPrimary': textOnPrimary,
      if (buttonPrimary != null) 'buttonPrimary': buttonPrimary,
      if (buttonPrimaryText != null) 'buttonPrimaryText': buttonPrimaryText,
      if (buttonSecondaryBorder != null)
        'buttonSecondaryBorder': buttonSecondaryBorder,
      if (buttonSecondaryText != null)
        'buttonSecondaryText': buttonSecondaryText,
      if (buttonDisabled != null) 'buttonDisabled': buttonDisabled,
      if (success != null) 'success': success,
      if (error != null) 'error': error,
      if (warning != null) 'warning': warning,
      if (border != null) 'border': border,
      if (divider != null) 'divider': divider,
      if (tint != null) 'tint': tint,
    };
  }
}

class BexTheme {
  const BexTheme({
    this.colors,
    this.buttonCornerRadius,
    this.buttonBorderWidth,
    this.buttonCapsule,
  });

  final BexThemeColors? colors;

  /// Button corner radius in density-independent pixels.
  final double? buttonCornerRadius;
  final double? buttonBorderWidth;

  /// When true on iOS, uses capsule button corners.
  final bool? buttonCapsule;

  Map<String, dynamic> toMap() {
    return {
      if (colors != null) 'colors': colors!.toMap(),
      if (buttonCornerRadius != null) 'buttonCornerRadius': buttonCornerRadius,
      if (buttonBorderWidth != null) 'buttonBorderWidth': buttonBorderWidth,
      if (buttonCapsule != null) 'buttonCapsule': buttonCapsule,
    };
  }
}

class InitializeConfig {
  const InitializeConfig({
    required this.authToken,
    required this.merchantId,
    required this.merchantUserId,
    required this.gsmNo,
    required this.environment,
    this.currencyCode,
    this.transactionType,
    this.installmentCount,
    this.theme,
    this.troySonicSoundEnabled,
    this.extras,
  });

  final String authToken;
  final String merchantId;
  final String merchantUserId;
  final String gsmNo;
  final BexEnvironment environment;

  /// ISO 4217 currency. Required for iOS initialize; default for Android pay.
  final String? currencyCode;

  /// Used by iOS initialize. Defaults to sale.
  final TransactionType? transactionType;

  /// Used by iOS initialize. Defaults to 1.
  final int? installmentCount;
  final BexTheme? theme;

  /// Android-only. Ignored on iOS.
  final bool? troySonicSoundEnabled;

  /// Forward-compatible native flags. Unstable.
  final Map<String, dynamic>? extras;

  Map<String, dynamic> toMap() {
    return {
      'authToken': authToken,
      'merchantId': merchantId,
      'merchantUserId': merchantUserId,
      'gsmNo': gsmNo,
      'environment': environment.name,
      if (currencyCode != null) 'currencyCode': currencyCode,
      if (transactionType != null) 'transactionType': transactionType!.name,
      if (installmentCount != null) 'installmentCount': installmentCount,
      if (theme != null) 'theme': theme!.toMap(),
      if (troySonicSoundEnabled != null)
        'troySonicSoundEnabled': troySonicSoundEnabled,
      if (extras != null) 'extras': extras,
    };
  }
}

class PaymentData {
  const PaymentData({
    required this.amount,
    required this.orderId,
    required this.security,
    required this.installmentCount,
    this.currency,
    this.transactionType,
    this.transactionId,
    this.transactionDate,
    this.successUrl,
    this.failUrl,
    this.extras,
  });

  final double amount;
  final String orderId;
  final PaymentSecurity security;
  final int installmentCount;
  final String? currency;
  final TransactionType? transactionType;

  /// Auto-generated UUID when omitted.
  final String? transactionId;
  final String? transactionDate;
  final String? successUrl;
  final String? failUrl;
  final Map<String, dynamic>? extras;

  Map<String, dynamic> toMap() {
    return {
      'amount': amount,
      'orderId': orderId,
      'security': security.name,
      'installmentCount': installmentCount,
      if (currency != null) 'currency': currency,
      if (transactionType != null) 'transactionType': transactionType!.name,
      if (transactionId != null) 'transactionId': transactionId,
      if (transactionDate != null) 'transactionDate': transactionDate,
      if (successUrl != null) 'successUrl': successUrl,
      if (failUrl != null) 'failUrl': failUrl,
      if (extras != null) 'extras': extras,
    };
  }
}

class FlowOptions {
  const FlowOptions({
    this.style,
    this.theme,
    this.extras,
  });

  final PresentationStyle? style;
  final BexTheme? theme;
  final Map<String, dynamic>? extras;

  Map<String, dynamic> toMap() {
    return {
      if (style != null) 'style': style!.name,
      if (theme != null) 'theme': theme!.toMap(),
      if (extras != null) 'extras': extras,
    };
  }
}

class BexBankInformation {
  const BexBankInformation({
    required this.cardType,
    required this.cardBrandType,
    required this.cardBrand,
    required this.bankShortName,
    this.bankCode,
    this.cardScheme,
  });

  final String cardType;
  final String cardBrandType;
  final String cardBrand;
  final String bankShortName;
  final String? bankCode;
  final String? cardScheme;

  factory BexBankInformation.fromMap(Map<Object?, Object?> map) {
    return BexBankInformation(
      cardType: map['cardType']?.toString() ?? '',
      cardBrandType: map['cardBrandType']?.toString() ?? '',
      cardBrand: map['cardBrand']?.toString() ?? '',
      bankShortName: map['bankShortName']?.toString() ?? '',
      bankCode: map['bankCode']?.toString(),
      cardScheme: map['cardScheme']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'cardType': cardType,
        'cardBrandType': cardBrandType,
        'cardBrand': cardBrand,
        'bankShortName': bankShortName,
        if (bankCode != null) 'bankCode': bankCode,
        if (cardScheme != null) 'cardScheme': cardScheme,
      };
}

class BexCard {
  const BexCard({
    required this.cardId,
    required this.maskCardNumber,
    required this.bankInformation,
    this.cardAlias,
    this.binValue,
    this.imageUrl,
    this.active,
  });

  final String cardId;
  final String maskCardNumber;
  final String? cardAlias;
  final String? binValue;
  final String? imageUrl;
  final BexBankInformation bankInformation;
  final bool? active;

  factory BexCard.fromMap(Map<Object?, Object?> map) {
    final bankRaw = map['bankInformation'];
    final bankMap = bankRaw is Map
        ? Map<Object?, Object?>.from(bankRaw)
        : <Object?, Object?>{};
    return BexCard(
      cardId: map['cardId']?.toString() ?? '',
      maskCardNumber: map['maskCardNumber']?.toString() ?? '',
      cardAlias: map['cardAlias']?.toString(),
      binValue: map['binValue']?.toString(),
      imageUrl: map['imageUrl']?.toString(),
      bankInformation: BexBankInformation.fromMap(bankMap),
      active: map['active'] as bool?,
    );
  }

  Map<String, dynamic> toJson() => {
        'cardId': cardId,
        'maskCardNumber': maskCardNumber,
        if (cardAlias != null) 'cardAlias': cardAlias,
        if (binValue != null) 'binValue': binValue,
        if (imageUrl != null) 'imageUrl': imageUrl,
        'bankInformation': bankInformation.toJson(),
        if (active != null) 'active': active,
      };
}

sealed class PayResult {
  const PayResult();

  factory PayResult.fromMap(Map<Object?, Object?> map) {
    final status = map['status']?.toString();
    if (status == 'cancelled') {
      return const PayCancelled();
    }
    return PayCompleted(
      transactionId: map['transactionId']?.toString() ?? '',
      amount: (map['amount'] as num?)?.toDouble() ?? 0,
      cardNumber: map['cardNumber']?.toString(),
    );
  }

  Map<String, dynamic> toJson();
}

class PayCompleted extends PayResult {
  const PayCompleted({
    required this.transactionId,
    required this.amount,
    this.cardNumber,
  });

  final String transactionId;
  final double amount;
  final String? cardNumber;

  String get status => 'completed';

  @override
  Map<String, dynamic> toJson() => {
        'status': status,
        'transactionId': transactionId,
        'amount': amount,
        if (cardNumber != null) 'cardNumber': cardNumber,
      };
}

class PayCancelled extends PayResult {
  const PayCancelled();

  String get status => 'cancelled';

  @override
  Map<String, dynamic> toJson() => {'status': status};
}

sealed class SelectCardResult {
  const SelectCardResult();

  factory SelectCardResult.fromMap(Map<Object?, Object?> map) {
    final status = map['status']?.toString();
    if (status == 'cancelled') {
      return const SelectCardCancelled();
    }
    final cardRaw = map['card'];
    final cardMap = cardRaw is Map
        ? Map<Object?, Object?>.from(cardRaw)
        : <Object?, Object?>{};
    return SelectCardSelected(card: BexCard.fromMap(cardMap));
  }

  Map<String, dynamic> toJson();
}

class SelectCardSelected extends SelectCardResult {
  const SelectCardSelected({required this.card});

  final BexCard card;

  String get status => 'selected';

  @override
  Map<String, dynamic> toJson() => {
        'status': status,
        'card': card.toJson(),
      };
}

class SelectCardCancelled extends SelectCardResult {
  const SelectCardCancelled();

  String get status => 'cancelled';

  @override
  Map<String, dynamic> toJson() => {'status': status};
}

class InitializeResult {
  const InitializeResult({this.ok = true});

  final bool ok;

  factory InitializeResult.fromMap(Map<Object?, Object?> map) {
    return InitializeResult(ok: map['ok'] == true);
  }

  Map<String, dynamic> toJson() => {'ok': ok};
}
