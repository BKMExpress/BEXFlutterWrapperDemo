# bex_flutter

BKM Express Full SDK için Flutter wrapper (Android + iOS).

## Gereksinimler

- Flutter 3.24+
- Android: minSdk 24, compileSdk 36+
- iOS: 15.0+, [CocoaPods](https://cocoapods.org/)
- Xcode (iOS build için)

## Kurulum

Paket **git** üzerinden dağıtılır:

```yaml
dependencies:
  bex_flutter:
    git:
      url: https://github.com/BKMExpress/bex-flutter.git
      path: packages/bex_flutter
```

Ardından:

```bash
flutter pub get
```

Monorepo içinde geliştirirken:

```yaml
dependencies:
  bex_flutter:
    path: ../bex_flutter
```

### Android

Entegrasyon yapılan uygulamanın `android/build.gradle.kts` (veya eşdeğer Gradle dosyasına) BKM Express Maven reposunu ekleyin:

```kotlin
allprojects {
  repositories {
    google()
    mavenCentral()
    maven {
      url = uri("https://entegrasyon-repo.bkmexpress.com.tr/repository/bkm-mobil-sdk/")
    }
  }
}
```

Plugin native bağımlılığı kendisi tanımlar: `com.bkm.mobil:full-sdk:0.0.5`.

### iOS

Bu plugin BKM Express XCFramework’ünü **CocoaPods** ile getirir (`podspec` içindeki `prepare_command` Nexus zip’ini indirir). Resmi native iOS SDK dokümanındaki SPM yolu burada kullanılmaz; Flutter plugin entegrasyonu CocoaPods üzerindendir.

İlk kurulum:

```bash
flutter precache --ios
flutter config --no-enable-swift-package-manager
cd ios && pod install
```

`pod install` XCFramework `1.0.7` dosyasını otomatik indirir.

> Flutter, `bex_flutter` için “SPM desteklemiyor” uyarısı verebilir; beklenen davranıştır. Plugin CocoaPods ile çalışır.

## Kullanım

```dart
import 'package:bex_flutter/bex_flutter.dart';

// 1) Bir kez initialize edin
await BexFullSdk.initialize(
  InitializeConfig(
    authToken: '...',
    merchantId: '...',
    merchantUserId: '...',
    gsmNo: '5XXXXXXXXX',
    environment: BexEnvironment.dev, // .test | .preprod | .prod
    currencyCode: 'TRY',
  ),
);

// 2) Ödeme
final payResult = await BexFullSdk.pay(
  PaymentData(
    amount: 100,
    orderId: 'ORDER_123',
    security: PaymentSecurity.none, // .none | .otp | .tds
    installmentCount: 1,
    currency: 'TRY',
    transactionType: TransactionType.sale, // .sale | .preAuth
    successUrl: 'https://merchant.example.com/success',
    failUrl: 'https://merchant.example.com/fail',
  ),
  const FlowOptions(style: PresentationStyle.fullScreen), // .fullScreen | .sheet
);

if (payResult is PayCompleted) {
  // payResult.transactionId, payResult.amount
}

// 3) Kart seçimi
final cardResult = await BexFullSdk.selectCard(
  PaymentData(
    amount: 100,
    orderId: 'ORDER_123',
    security: PaymentSecurity.none,
    installmentCount: 1,
    currency: 'TRY',
  ),
  const FlowOptions(style: PresentationStyle.fullScreen),
);

if (cardResult is SelectCardSelected) {
  // cardResult.card
}
```

İptal durumunda `{ status: cancelled }` döner (exception fırlatılmaz). Hatalar `BexError` fırlatır.

```dart
try {
  await BexFullSdk.pay(/* ... */);
} catch (error) {
  final bexError = BexError.fromPlatform(error);
  // bexError.code, bexError.message
}
```

## API

- `BexFullSdk.initialize(config)`
- `BexFullSdk.pay(payment, [options])`
- `BexFullSdk.selectCard([paymentOrOptions], [options])`
- `BexError`

### Önemli tipler

| Tip | Değerler |
|-----|----------|
| `BexEnvironment` | `test`, `preprod`, `prod` |
| `PaymentSecurity` | `none`, `otp`, `tds` |
| `TransactionType` | `sale`, `preAuth`, `recurring` |
| `PresentationStyle` | `fullScreen`, `sheet` |

`transactionType` native Android SDK’da `/sdk/init` isteğine enum adı olarak gider (`SALE`, `PRE_AUTH`, `RECURRING`).

## Platform davranış notları

| Konu | Android | iOS |
|------|---------|-----|
| `initialize` | Konfigürasyonu saklar (lazy) | Gerçek `BKMExpress.initialize` → token |
| İptal | `{ status: cancelled }` | `{ status: cancelled }` |
| Eşzamanlı akış | `already_in_progress` | `already_in_progress` |

## Native SDK sürümleri (0.1.0)

| Platform | Bağımlılık |
|----------|------------|
| Android | `com.bkm.mobil:full-sdk:0.0.5` |
| iOS | XCFramework `1.0.7` (CocoaPods `prepare_command` ile) |
