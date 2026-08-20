package com.bkm.bexflutter

import android.app.Activity
import android.content.Context
import android.graphics.Color
import com.bkm.mobil.sdk.api.BexEnvironment
import com.bkm.mobil.sdk.api.BexFullSdk
import com.bkm.mobil.sdk.api.BexFullSdkConfig
import com.bkm.mobil.sdk.api.BexFullSdkTheme
import com.bkm.mobil.sdk.api.BexSdkError
import com.bkm.mobil.sdk.api.CardSelectionResult
import com.bkm.mobil.sdk.api.PaymentCallback
import com.bkm.mobil.sdk.api.PaymentResult
import com.bkm.mobil.sdk.api.PaymentSecurity
import com.bkm.mobil.sdk.api.SdkInitParams
import com.bkm.mobil.sdk.api.SdkMode
import com.bkm.mobil.sdk.api.SdkPaymentInfo
import com.bkm.mobil.sdk.api.TransactionType
import io.flutter.plugin.common.MethodChannel
import java.util.UUID
import java.util.concurrent.atomic.AtomicBoolean

class BexFullSdkBridge {
  private var appContext: Context? = null
  private var activityProvider: (() -> Activity?)? = null
  private var initializeConfig: Map<String, Any?>? = null
  private val flowInProgress = AtomicBoolean(false)

  fun attach(context: Context, activityProvider: () -> Activity?) {
    appContext = context.applicationContext
    this.activityProvider = activityProvider
  }

  fun initialize(config: Map<String, Any?>, result: MethodChannel.Result) {
    try {
      requireString(config, "authToken")
      requireString(config, "merchantId")
      requireString(config, "merchantUserId")
      requireString(config, "gsmNo")
      requireString(config, "environment")
      initializeConfig = config
      result.success(mapOf("ok" to true))
    } catch (error: Exception) {
      rejectError(result, "invalid_argument", error.message ?: "Invalid initialize config.")
    }
  }

  fun pay(
    payment: Map<String, Any?>,
    options: Map<String, Any?>,
    result: MethodChannel.Result
  ) {
    startFlow(
      mode = SdkMode.PAYMENT,
      payment = payment,
      options = options,
      result = result
    )
  }

  fun selectCard(options: Map<String, Any?>, result: MethodChannel.Result) {
    @Suppress("UNCHECKED_CAST")
    val paymentFromOptions = options["payment"] as? Map<String, Any?>
    startFlow(
      mode = SdkMode.CARD_SELECTION_ONLY,
      payment = paymentFromOptions,
      options = options,
      result = result
    )
  }

  private fun startFlow(
    mode: SdkMode,
    payment: Map<String, Any?>?,
    options: Map<String, Any?>,
    result: MethodChannel.Result
  ) {
    val config = initializeConfig
    if (config == null) {
      rejectError(result, "not_initialized", "Call BexFullSdk.initialize() before pay/selectCard.")
      return
    }

    if (!flowInProgress.compareAndSet(false, true)) {
      rejectError(result, "already_in_progress", "A BEX SDK flow is already in progress.")
      return
    }

    val activity = activityProvider?.invoke()
    val style = optionalString(options, "style") ?: "fullScreen"
    if (style == "sheet" && activity == null) {
      flowInProgress.set(false)
      rejectError(
        result,
        "no_activity",
        "No current Activity available for bottom sheet presentation."
      )
      return
    }

    try {
      val initParams = buildInitParams(config, payment)
      val theme = resolveTheme(config, options)
      val troySonic = when (val value = config["troySonicSoundEnabled"]) {
        is Boolean -> value
        else -> true
      }

      val settled = AtomicBoolean(false)

      fun settleSuccess(map: Map<String, Any?>) {
        if (settled.compareAndSet(false, true)) {
          flowInProgress.set(false)
          result.success(map)
        }
      }

      fun settleReject(
        code: String,
        message: String,
        title: String? = null,
        nativeCode: Int? = null
      ) {
        if (settled.compareAndSet(false, true)) {
          flowInProgress.set(false)
          rejectError(result, code, message, title, nativeCode)
        }
      }

      val initContext = activity ?: appContext
      if (initContext == null) {
        flowInProgress.set(false)
        rejectError(result, "no_activity", "No Android context available.")
        return
      }

      BexFullSdk.init(
        context = initContext,
        initParams = initParams,
        callback = object : PaymentCallback {
          override fun onPaymentSuccess(paymentResult: PaymentResult) {
            val map = mutableMapOf<String, Any?>(
              "status" to "completed",
              "transactionId" to paymentResult.transactionId,
              "amount" to paymentResult.amount
            )
            if (paymentResult.cardNumber != null) {
              map["cardNumber"] = paymentResult.cardNumber
            }
            settleSuccess(map)
          }

          override fun onCardSelected(cardResult: CardSelectionResult) {
            val card = cardResult.selectedCard
            val bank = mapOf(
              "cardType" to card.bexBankInformation.cardType,
              "cardBrandType" to card.bexBankInformation.cardBrandType,
              "cardBrand" to card.bexBankInformation.cardBrand,
              "bankShortName" to card.bexBankInformation.bankShortName
            )

            val cardMap = mutableMapOf<String, Any?>(
              "cardId" to card.cardId,
              "maskCardNumber" to card.maskCardNumber,
              "bankInformation" to bank,
              "active" to card.active
            )
            card.cardAlias?.let { cardMap["cardAlias"] = it }
            card.binValue?.let { cardMap["binValue"] = it }
            card.imageUrl?.let { cardMap["imageUrl"] = it }

            settleSuccess(
              mapOf(
                "status" to "selected",
                "card" to cardMap
              )
            )
          }

          override fun onError(error: BexSdkError) {
            if (error is BexSdkError.Cancelled) {
              settleSuccess(mapOf("status" to "cancelled"))
              return
            }

            when (error) {
              is BexSdkError.Network -> settleReject("network", error.displayMessage)
              is BexSdkError.Unauthorized -> settleReject("unauthorized", error.displayMessage)
              is BexSdkError.Api -> settleReject(
                "api",
                error.displayMessage,
                error.title,
                error.code
              )
              is BexSdkError.Unknown -> settleReject("unknown", error.displayMessage)
              is BexSdkError.Cancelled -> settleReject("cancelled", error.displayMessage)
            }
          }
        },
        theme = theme,
        config = BexFullSdkConfig(
          troySonicSoundEnabled = troySonic,
          mode = mode
        )
      )

      if (style == "sheet") {
        BexFullSdk.showAsBottomSheet(activity as Activity)
      } else {
        BexFullSdk.start()
      }
    } catch (error: Exception) {
      flowInProgress.set(false)
      rejectError(result, "unknown", error.message ?: "Failed to start BEX SDK flow.")
    }
  }

  private fun buildInitParams(
    config: Map<String, Any?>,
    payment: Map<String, Any?>?
  ): SdkInitParams {
    val currencyDefault = mapString(config, "currencyCode") ?: "TRY"
    val paymentInfo = buildPaymentInfo(config, payment, currencyDefault)

    return SdkInitParams(
      token = requireString(config, "authToken"),
      merchantId = requireString(config, "merchantId"),
      transactionId = optionalString(payment, "transactionId") ?: UUID.randomUUID().toString(),
      gsmNo = requireString(config, "gsmNo"),
      merchantUserId = requireString(config, "merchantUserId"),
      paymentInfo = paymentInfo,
      environment = mapEnvironment(requireString(config, "environment"))
    )
  }

  private fun buildPaymentInfo(
    config: Map<String, Any?>,
    payment: Map<String, Any?>?,
    currencyDefault: String
  ): SdkPaymentInfo {
    val amount = when (val raw = payment?.get("amount")) {
      is Number -> raw.toDouble()
      else -> 100.0
    }
    val installmentCount = when (val raw = payment?.get("installmentCount")) {
      is Number -> raw.toInt()
      else -> (config["installmentCount"] as? Number)?.toInt() ?: 1
    }

    return SdkPaymentInfo(
      amount = amount,
      orderId = optionalString(payment, "orderId")
        ?: "DEMO-${System.currentTimeMillis()}",
      transactionDate = optionalString(payment, "transactionDate")
        ?: System.currentTimeMillis().toString(),
      paymentSecurity = mapPaymentSecurity(optionalString(payment, "security") ?: "none"),
      currency = optionalString(payment, "currency") ?: currencyDefault,
      installmentCount = installmentCount,
      transactionType = mapTransactionType(
        optionalString(payment, "transactionType")
          ?: mapString(config, "transactionType")
          ?: "sale"
      ),
      successUrl = optionalString(payment, "successUrl")
        ?: "https://trcuzdan-dev.bkmtest.com.tr/sdk/demo/success",
      failUrl = optionalString(payment, "failUrl")
        ?: "https://trcuzdan-dev.bkmtest.com.tr/sdk/demo/fail"
    )
  }

  @Suppress("UNCHECKED_CAST")
  private fun resolveTheme(
    config: Map<String, Any?>,
    options: Map<String, Any?>
  ): BexFullSdkTheme? {
    val themeMap = (options["theme"] as? Map<String, Any?>)
      ?: (config["theme"] as? Map<String, Any?>)
      ?: return null

    val colorsMap = themeMap["colors"] as? Map<String, Any?>
    val colors = colorsMap?.let {
      BexFullSdkTheme.Colors(
        primary = parseColor(mapString(it, "primary")),
        primaryVariant = parseColor(mapString(it, "primaryVariant")),
        background = parseColor(mapString(it, "background")),
        surface = parseColor(mapString(it, "surface")),
        textPrimary = parseColor(mapString(it, "textPrimary")),
        textSecondary = parseColor(mapString(it, "textSecondary")),
        textOnPrimary = parseColor(mapString(it, "textOnPrimary")),
        buttonPrimary = parseColor(mapString(it, "buttonPrimary")),
        buttonPrimaryText = parseColor(mapString(it, "buttonPrimaryText")),
        buttonSecondaryBorder = parseColor(mapString(it, "buttonSecondaryBorder")),
        buttonSecondaryText = parseColor(mapString(it, "buttonSecondaryText")),
        buttonDisabled = parseColor(mapString(it, "buttonDisabled")),
        success = parseColor(mapString(it, "success")),
        error = parseColor(mapString(it, "error")),
        warning = parseColor(mapString(it, "warning")),
        border = parseColor(mapString(it, "border")),
        divider = parseColor(mapString(it, "divider"))
      )
    }

    val shape = BexFullSdkTheme.Shape(
      buttonCornerRadius = (themeMap["buttonCornerRadius"] as? Number)?.toFloat(),
      buttonBorderWidth = (themeMap["buttonBorderWidth"] as? Number)?.toFloat()
    )

    return BexFullSdkTheme(colors = colors, shape = shape)
  }

  private fun mapEnvironment(value: String): BexEnvironment = when (value.lowercase()) {
    "dev" -> BexEnvironment.DEV
    "test" -> BexEnvironment.TEST
    "preprod" -> BexEnvironment.PREPROD
    "prod" -> BexEnvironment.PROD
    else -> throw IllegalArgumentException("Unsupported environment: $value")
  }

  private fun mapPaymentSecurity(value: String): PaymentSecurity = when (value.lowercase()) {
    "tds" -> PaymentSecurity.TDS
    "otp" -> PaymentSecurity.OTP
    "none" -> PaymentSecurity.NONE
    else -> throw IllegalArgumentException("Unsupported payment security: $value")
  }

  private fun mapTransactionType(value: String): TransactionType = when (value.lowercase()) {
    "sale" -> TransactionType.SALE
    "preauth", "pre_auth" -> TransactionType.PRE_AUTH
    "recurring" -> TransactionType.RECURRING
    else -> throw IllegalArgumentException("Unsupported transaction type: $value")
  }

  private fun parseColor(value: String?): Int? {
    if (value.isNullOrBlank()) return null
    val normalized = if (value.startsWith("#")) value else "#$value"
    return try {
      Color.parseColor(normalized)
    } catch (_: IllegalArgumentException) {
      if (normalized.length == 9) {
        val rgb = normalized.substring(1, 7)
        val alpha = normalized.substring(7, 9)
        Color.parseColor("#$alpha$rgb")
      } else {
        null
      }
    }
  }

  private fun requireString(map: Map<String, Any?>, key: String): String {
    val value = mapString(map, key)?.trim()
    require(!value.isNullOrEmpty()) { "$key is required." }
    return value
  }

  private fun optionalString(map: Map<String, Any?>?, key: String): String? {
    if (map == null) return null
    return mapString(map, key)
  }

  private fun mapString(map: Map<String, Any?>, key: String): String? {
    return map[key]?.toString()
  }

  private fun rejectError(
    result: MethodChannel.Result,
    code: String,
    message: String,
    title: String? = null,
    nativeCode: Int? = null
  ) {
    val details = mutableMapOf<String, Any?>(
      "code" to code,
      "message" to message
    )
    if (title != null) details["title"] = title
    if (nativeCode != null) details["nativeCode"] = nativeCode
    result.error(code, message, details)
  }
}
