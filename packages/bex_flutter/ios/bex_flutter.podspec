#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

BKM_IOS_SDK_VERSION = "1.0.7" unless defined?(BKM_IOS_SDK_VERSION)
BKM_IOS_SDK_URL = "https://entegrasyon-repo.bkmexpress.com.tr/repository/swift/iossdk/ios_full_sdk/#{BKM_IOS_SDK_VERSION}.zip" unless defined?(BKM_IOS_SDK_URL)

Pod::Spec.new do |s|
  s.name             = 'bex_flutter'
  s.version          = '0.1.0'
  s.summary          = 'Flutter wrapper for BKM Express Full SDK'
  s.description      = <<-DESC
Flutter plugin that bridges BKM Express Full SDK for Android and iOS.
                       DESC
  s.homepage         = 'https://www.bkmexpress.com.tr'
  s.license          = { :type => 'MIT' }
  s.author           = { 'BKM' => 'mobil@bkm.com.tr' }
  s.source           = { :path => '.' }
  s.source_files     = 'Classes/**/*'
  s.dependency 'Flutter'
  s.platform         = :ios, '15.0'
  s.swift_version    = '5.9'
  s.static_framework = true

  # Download the official BKM Express XCFramework on pod install (not vendored in git).
  s.prepare_command = <<-CMD
    set -e
    FRAMEWORKS_DIR="Frameworks"
    mkdir -p "$FRAMEWORKS_DIR"
    if [ ! -d "$FRAMEWORKS_DIR/BKMExpressSDK.xcframework" ]; then
      TMP_ZIP="$(mktemp -t bkm-ios-sdk).zip"
      TMP_DIR="$(mktemp -d -t bkm-ios-sdk)"
      curl -fsSL "#{BKM_IOS_SDK_URL}" -o "$TMP_ZIP"
      unzip -qo "$TMP_ZIP" -d "$TMP_DIR"
      FOUND="$(find "$TMP_DIR" -type d -name 'BKMExpressSDK.xcframework' | head -n 1)"
      if [ -z "$FOUND" ]; then
        echo "BKMExpressSDK.xcframework not found in SDK archive" >&2
        exit 1
      fi
      rm -rf "$FRAMEWORKS_DIR/BKMExpressSDK.xcframework"
      mv "$FOUND" "$FRAMEWORKS_DIR/BKMExpressSDK.xcframework"
      rm -rf "$TMP_ZIP" "$TMP_DIR"
    fi
  CMD

  s.vendored_frameworks = 'Frameworks/BKMExpressSDK.xcframework'
  s.frameworks = 'UIKit', 'Foundation'

  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
end
