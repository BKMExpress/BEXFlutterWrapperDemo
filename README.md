# bex-flutter

BKM Express Flutter wrapper için monorepo.

```
packages/
  bex_flutter/   # yayınlanan paket
  demo/          # örnek uygulama
```

Entegrasyon ve kullanım dokümanı: [`packages/bex_flutter/README.md`](packages/bex_flutter/README.md)

## Local geliştirmeler için

```bash
# Monorepo root
dart pub get

cd packages/demo
flutter pub get

# Bağlı cihazları listele
flutter devices

# Android
flutter run -d <androidDeviceId>

# iOS — ilk seferde
flutter precache --ios
flutter config --no-enable-swift-package-manager
cd ios && pod install && cd ..
flutter run -d <iosDeviceId>
```

Demo, `bex_flutter` paketini path dependency olarak kullanır.

