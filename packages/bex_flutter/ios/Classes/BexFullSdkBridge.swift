import Foundation
import UIKit
import Flutter
import BKMExpressSDK

final class BexFullSdkBridge {
  static let shared = BexFullSdkBridge()

  private var initializationToken: BKMExpress.InitializationToken?
  private var initializeConfig: [String: Any] = [:]
  private var flowInProgress = false

  func initialize(_ config: [String: Any], result: @escaping FlutterResult) {
    guard
      let authToken = stringValue(config["authToken"]), !authToken.isEmpty,
      let merchantId = stringValue(config["merchantId"]), !merchantId.isEmpty,
      let merchantUserId = stringValue(config["merchantUserId"]), !merchantUserId.isEmpty,
      let gsmRaw = stringValue(config["gsmNo"]), !gsmRaw.isEmpty,
      let environment = stringValue(config["environment"]), !environment.isEmpty
    else {
      reject(result, code: "invalid_argument", message: "Missing required initialize fields.")
      return
    }

    let currencyCode = stringValue(config["currencyCode"]) ?? "TRY"
    let transactionType = mapTransactionType(stringValue(config["transactionType"]) ?? "sale")
    let installmentRaw = (config["installmentCount"] as? NSNumber)?.intValue ?? 1

    guard let installmentCount = BKMExpress.InstallmentCount(installmentRaw) else {
      reject(result, code: "invalid_argument", message: "installmentCount must be a positive integer.")
      return
    }

    let gsmNo: BKMExpress.GSMNO
    do {
      gsmNo = try BKMExpress.GSMNO(gsmRaw)
    } catch {
      reject(
        result,
        code: "invalid_argument",
        message: "gsmNo must be a valid Turkish mobile number (5XXXXXXXXX)."
      )
      return
    }

    initializeConfig = config

    Task { @MainActor in
      do {
        let token = try await BKMExpress.initialize(
          context: .init(
            authToken: authToken,
            merchantID: merchantId,
            merchantUserID: merchantUserId,
            gsmNo: gsmNo,
            currencyCode: currencyCode,
            transactionType: transactionType,
            installmentCount: installmentCount,
            mode: mapMode(environment)
          )
        )
        self.initializationToken = token
        result(["ok": true])
      } catch let failure as BKMExpress.Failure {
        self.reject(result, code: self.mapFailureCode(failure), message: failure.message)
      } catch {
        self.reject(result, code: "unknown", message: error.localizedDescription)
      }
    }
  }

  func pay(
    _ payment: [String: Any],
    options: [String: Any],
    result: @escaping FlutterResult
  ) {
    guard let token = initializationToken else {
      reject(result, code: "not_initialized", message: "Call BexFullSdk.initialize() before pay/selectCard.")
      return
    }

    guard !flowInProgress else {
      reject(result, code: "already_in_progress", message: "A BEX SDK flow is already in progress.")
      return
    }

    guard
      let amountNumber = payment["amount"] as? NSNumber,
      let orderId = stringValue(payment["orderId"]), !orderId.isEmpty,
      let securityRaw = stringValue(payment["security"]),
      let installmentRaw = payment["installmentCount"] as? NSNumber
    else {
      reject(result, code: "invalid_argument", message: "Invalid payment payload.")
      return
    }

    guard let installmentCount = BKMExpress.InstallmentCount(installmentRaw.intValue) else {
      reject(result, code: "invalid_argument", message: "installmentCount must be a positive integer.")
      return
    }

    guard let presenter = Self.topViewController() else {
      reject(result, code: "no_activity", message: "No UIViewController available to present BKM Express.")
      return
    }

    let transactionIdString = stringValue(payment["transactionId"])
    let transactionID = transactionIdString.flatMap(UUID.init(uuidString:)) ?? UUID()
    let transactionDate = parseDate(stringValue(payment["transactionDate"])) ?? Date()

    flowInProgress = true
    let style = mapStyle(stringValue(options["style"]) ?? "fullScreen")
    let theme = resolveTheme(options: options)

    let paymentData = BKMExpress.PaymentData(
      amount: Decimal(amountNumber.doubleValue),
      security: mapSecurity(securityRaw),
      installmentCount: installmentCount,
      transactionType: mapTransactionType(stringValue(payment["transactionType"]) ?? "sale"),
      transactionID: transactionID,
      transactionDate: transactionDate,
      orderID: orderId,
      successUrl: stringValue(payment["successUrl"]) ?? "",
      failUrl: stringValue(payment["failUrl"]) ?? ""
    )

    DispatchQueue.main.async {
      BKMExpress.pay(
        token: token,
        data: paymentData,
        theme: theme,
        style: style,
        on: presenter
      ) { [weak self] payResult in
        guard let self else { return }
        self.flowInProgress = false
        switch payResult {
        case .completed:
          result([
            "status": "completed",
            "transactionId": transactionID.uuidString,
            "amount": amountNumber.doubleValue,
          ])
        case .cancelled:
          result(["status": "cancelled"])
        case .failed(let failure):
          if failure.isCancelled || self.mapFailureCode(failure) == "cancelled" {
            result(["status": "cancelled"])
          } else {
            self.reject(result, code: self.mapFailureCode(failure), message: failure.message)
          }
        }
      }
    }
  }

  func selectCard(_ options: [String: Any], result: @escaping FlutterResult) {
    guard let token = initializationToken else {
      reject(result, code: "not_initialized", message: "Call BexFullSdk.initialize() before pay/selectCard.")
      return
    }

    guard !flowInProgress else {
      reject(result, code: "already_in_progress", message: "A BEX SDK flow is already in progress.")
      return
    }

    guard let presenter = Self.topViewController() else {
      reject(result, code: "no_activity", message: "No UIViewController available to present BKM Express.")
      return
    }

    flowInProgress = true
    let style = mapStyle(stringValue(options["style"]) ?? "fullScreen")
    let theme = resolveTheme(options: options)

    DispatchQueue.main.async {
      BKMExpress.selectCard(
        token: token,
        theme: theme,
        style: style,
        on: presenter
      ) { [weak self] cardResult in
        guard let self else { return }
        self.flowInProgress = false
        switch cardResult {
        case .selected(let card):
          result([
            "status": "selected",
            "card": self.mapCard(card),
          ])
        case .cancelled:
          result(["status": "cancelled"])
        case .failed(let failure):
          if failure.isCancelled || self.mapFailureCode(failure) == "cancelled" {
            result(["status": "cancelled"])
          } else {
            self.reject(result, code: self.mapFailureCode(failure), message: failure.message)
          }
        }
      }
    }
  }

  private func mapCard(_ card: BKMExpress.Card) -> [String: Any] {
    var payload: [String: Any] = [
      "cardId": card.id.rawValue,
      "maskCardNumber": card.maskedCardNumber,
      "cardAlias": card.alias,
      "binValue": card.bin,
      "bankInformation": [
        "cardType": card.bankInformation.cardType,
        "cardBrandType": card.bankInformation.cardScheme,
        "cardBrand": card.bankInformation.cardBrand,
        "bankShortName": card.bankInformation.bankShortName,
        "bankCode": card.bankInformation.bankCode,
        "cardScheme": card.bankInformation.cardScheme,
      ] as [String: Any],
      "active": true,
    ]

    if let imageURL = card.imageURL?.absoluteString {
      payload["imageUrl"] = imageURL
    }

    return payload
  }

  private func resolveTheme(options: [String: Any]) -> BKMExpress.Theme {
    var theme = BKMExpress.Theme()

    let themeDict = (options["theme"] as? [String: Any])
      ?? (initializeConfig["theme"] as? [String: Any])

    guard let themeDict else { return theme }

    if let colors = themeDict["colors"] as? [String: Any] {
      let tintHex = stringValue(colors["tint"]) ?? stringValue(colors["primary"])
      if let tintHex, let color = UIColor(hex: tintHex) {
        theme.tint = color
      }
    }

    if let capsule = themeDict["buttonCapsule"] as? Bool, capsule {
      theme.buttonCornerRadius = .capsule
    } else if let radius = themeDict["buttonCornerRadius"] as? NSNumber {
      theme.buttonCornerRadius = .custom(CGFloat(truncating: radius))
    }

    return theme
  }

  private func mapMode(_ value: String) -> BKMExpress.Mode {
    switch value.lowercased() {
    case "preprod":
      return .preprod
    case "prod":
      return .production
    default:
      return .test
    }
  }

  private func mapSecurity(_ value: String) -> BKMExpress.PaymentSecurity {
    switch value.lowercased() {
    case "tds":
      return .tds
    case "otp":
      return .otp
    default:
      return .none
    }
  }

  private func mapTransactionType(_ value: String) -> BKMExpress.TransactionType {
    switch value.lowercased() {
    case "preauth", "pre_auth":
      return .preAuth
    case "recurring":
      return .recurring
    default:
      return .sale
    }
  }

  private func mapStyle(_ value: String) -> BKMExpress.PresentationStyle {
    value.lowercased() == "sheet" ? .sheet : .fullScreen
  }

  private func mapFailureCode(_ failure: BKMExpress.Failure) -> String {
    switch failure.kind {
    case .session:
      return "session"
    case .encryption:
      return "encryption"
    case .server:
      return "server"
    case .cancelled:
      return "cancelled"
    @unknown default:
      return "unknown"
    }
  }

  private func parseDate(_ value: String?) -> Date? {
    guard let value, !value.isEmpty else { return nil }
    if let millis = Double(value) {
      return Date(timeIntervalSince1970: millis > 10_000_000_000 ? millis / 1000.0 : millis)
    }
    let formatter = ISO8601DateFormatter()
    return formatter.date(from: value)
  }

  private func stringValue(_ value: Any?) -> String? {
    if let string = value as? String {
      return string
    }
    if let number = value as? NSNumber {
      return number.stringValue
    }
    return nil
  }

  private func reject(
    _ result: @escaping FlutterResult,
    code: String,
    message: String,
    title: String? = nil,
    nativeCode: Int? = nil
  ) {
    var details: [String: Any] = [
      "code": code,
      "message": message,
    ]
    if let title { details["title"] = title }
    if let nativeCode { details["nativeCode"] = nativeCode }
    result(
      FlutterError(code: code, message: message, details: details)
    )
  }

  private static func topViewController(
    base: UIViewController? = {
      UIApplication.shared.connectedScenes
        .compactMap { $0 as? UIWindowScene }
        .flatMap { $0.windows }
        .first { $0.isKeyWindow }?
        .rootViewController
    }()
  ) -> UIViewController? {
    if let navigation = base as? UINavigationController {
      return topViewController(base: navigation.visibleViewController)
    }
    if let tab = base as? UITabBarController {
      return topViewController(base: tab.selectedViewController)
    }
    if let presented = base?.presentedViewController {
      return topViewController(base: presented)
    }
    return base
  }
}

private extension UIColor {
  convenience init?(hex: String) {
    var normalized = hex.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
    if normalized.hasPrefix("#") {
      normalized.removeFirst()
    }

    var value: UInt64 = 0
    guard Scanner(string: normalized).scanHexInt64(&value) else {
      return nil
    }

    switch normalized.count {
    case 6:
      self.init(
        red: CGFloat((value & 0xFF0000) >> 16) / 255,
        green: CGFloat((value & 0x00FF00) >> 8) / 255,
        blue: CGFloat(value & 0x0000FF) / 255,
        alpha: 1
      )
    case 8:
      self.init(
        red: CGFloat((value & 0xFF000000) >> 24) / 255,
        green: CGFloat((value & 0x00FF0000) >> 16) / 255,
        blue: CGFloat((value & 0x0000FF00) >> 8) / 255,
        alpha: CGFloat(value & 0x000000FF) / 255
      )
    default:
      return nil
    }
  }
}
