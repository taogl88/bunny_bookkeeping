package com.guantou.ledger_flutter

import android.Manifest
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import android.telephony.SmsMessage
import android.util.Log
import androidx.core.app.NotificationCompat
import androidx.core.content.ContextCompat
import org.json.JSONObject
import java.util.regex.Pattern

class SmsReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action != smsReceivedAction) {
            return
        }
        Log.d(tag, "[SmsReceiver] onReceive: action=${intent.action}")
        val bundle = intent.extras ?: return
        val pdus = bundle.get("pdus") as? Array<*> ?: return
        val format = bundle.getString("format")
        val body = buildSmsBody(pdus, format).trim()
        if (body.isEmpty()) {
            Log.d(tag, "[SmsReceiver] onReceive: empty sms body")
            return
        }
        Log.d(tag, "[SmsReceiver] onReceive: body=$body")
        val transaction = parseTransaction(body) ?: return
        SmsPlugin.appendPendingTransaction(context, transaction)
        showNotification(context, transaction)
    }

    private fun buildSmsBody(pdus: Array<*>, format: String?): String {
        val bodyBuilder = StringBuilder()
        for (pdu in pdus) {
            val bytes = pdu as? ByteArray ?: continue
            val message = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                SmsMessage.createFromPdu(bytes, format)
            } else {
                @Suppress("DEPRECATION")
                SmsMessage.createFromPdu(bytes)
            }
            bodyBuilder.append(message.messageBody)
        }
        return bodyBuilder.toString()
    }

    private fun parseTransaction(body: String): JSONObject? {
        val expenseMatch = expenseDirectionPattern.matcher(body)
        val incomeMatch = incomeDirectionPattern.matcher(body)

        val type: String
        val amountSearchStart: Int
        when {
            incomeMatch.find() -> {
                type = "income"
                amountSearchStart = incomeMatch.end()
            }
            expenseMatch.find() -> {
                type = "expense"
                amountSearchStart = expenseMatch.end()
            }
            else -> {
                Log.d(tag, "[SmsReceiver] parseTransaction: no expense/income pattern match")
                return null
            }
        }
        val amount = extractTransactionAmount(body, amountSearchStart) ?: run {
            Log.d(tag, "[SmsReceiver] parseTransaction: money amount not found")
            return null
        }
        val dateMatch = datePattern.matcher(body)
        if (!dateMatch.find()) {
            Log.d(tag, "[SmsReceiver] parseTransaction: date pattern not found")
            return null
        }
        val bankName = extractBankName(body)
        val directionLabel = if (type == "expense") "支出" else "收入"
        Log.d(
            tag,
            "[SmsReceiver] parseTransaction: type=$type, amount=$amount, bankName=$bankName, date=${dateMatch.group(1)}, time=${dateMatch.group(2)}"
        )
        return JSONObject().apply {
            put("amount", amount)
            put("type", type)
            put("bankName", bankName)
            put("note", "${bankName}短信自动记账：$directionLabel")
            put("dateText", dateMatch.group(1) ?: "")
            put("timeText", dateMatch.group(2) ?: "")
            put("body", body)
        }
    }

    private fun extractTransactionAmount(body: String, searchStart: Int): Double? {
        val safeSearchStart = searchStart.coerceIn(0, body.length)
        val matcher = amountPattern.matcher(body.substring(safeSearchStart))
        while (matcher.find()) {
            val absoluteStart = safeSearchStart + matcher.start()
            if (isIgnoredAmountContext(body, absoluteStart)) {
                continue
            }

            val amountText = (matcher.group(1) ?: matcher.group(2) ?: "")
                .replace(",", "")
            val amount = amountText.toDoubleOrNull()
            if (amount != null && amount > 0) {
                return amount
            }
        }
        return null
    }

    private fun isIgnoredAmountContext(body: String, amountStart: Int): Boolean {
        val contextStart = (amountStart - amountContextLookBehind).coerceAtLeast(0)
        val prefix = body.substring(contextStart, amountStart)
        return ignoredAmountPrefixes.any { prefix.contains(it) }
    }

    private fun extractBankName(body: String): String {
        val bracketMatch = bracketBankPattern.matcher(body)
        if (bracketMatch.find()) {
            return bracketMatch.group(1) ?: defaultBankName
        }
        val inlineMatch = inlineBankPattern.matcher(body)
        if (inlineMatch.find()) {
            return inlineMatch.group(1) ?: defaultBankName
        }
        return defaultBankName
    }

    private fun showNotification(context: Context, transaction: JSONObject) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU &&
            ContextCompat.checkSelfPermission(
                context,
                Manifest.permission.POST_NOTIFICATIONS
            ) != PackageManager.PERMISSION_GRANTED
        ) {
            Log.d(tag, "[SmsReceiver] showNotification: skipped, POST_NOTIFICATIONS not granted")
            return
        }

        val notificationManager =
            context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                channelId,
                "自动记账通知",
                NotificationManager.IMPORTANCE_DEFAULT
            )
            notificationManager.createNotificationChannel(channel)
        }

        val launchIntent = Intent(context, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
        }
        val pendingIntent = PendingIntent.getActivity(
            context,
            0,
            launchIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val note = transaction.optString("note")
        val amount = transaction.optDouble("amount")
        val builder = NotificationCompat.Builder(context, channelId)
            .setSmallIcon(android.R.drawable.ic_dialog_info)
            .setContentTitle(note)
            .setContentText(String.format("%.2f 元", amount))
            .setPriority(NotificationCompat.PRIORITY_DEFAULT)
            .setAutoCancel(true)
            .setContentIntent(pendingIntent)

        notificationManager.notify(System.currentTimeMillis().toInt(), builder.build())
        Log.d(tag, "[SmsReceiver] showNotification: posted note=$note, amount=$amount")
    }

    companion object {
        private const val tag = "LedgerSms"
        private const val smsReceivedAction = "android.provider.Telephony.SMS_RECEIVED"
        private const val channelId = "ledger_sms_channel"
        private const val defaultBankName = "银行"
        private const val amountContextLookBehind = 12

        private val expenseDirectionPattern = Pattern.compile(
            "(?:于)?(\\d{1,2}月\\d{1,2}日).*?(支取|消费|支出|支付|扣款|付款)"
        )
        private val incomeDirectionPattern = Pattern.compile(
            "(?:于)?(\\d{1,2}月\\d{1,2}日).*?(工资|转入|汇入|存入|收入|入账)"
        )
        private val amountPattern = Pattern.compile(
            "(?:人民币|RMB|CNY|[¥￥])\\s*([0-9][0-9,]*(?:\\.[0-9]{1,2})?)\\s*(?:元|圆)?|([0-9][0-9,]*(?:\\.[0-9]{1,2})?)\\s*(?:元|圆)",
            Pattern.CASE_INSENSITIVE
        )
        private val datePattern = Pattern.compile("(\\d{1,2}月\\d{1,2}日)(\\d{1,2}:\\d{2})?")
        private val bracketBankPattern = Pattern.compile("【(.*?)】")
        private val inlineBankPattern = Pattern.compile("((?:工商|中国|建设|农业|交通|招商|邮储|中信|浦发|平安|兴业|民生|华夏)银行)")
        private val ignoredAmountPrefixes = listOf("余额", "可用余额", "账户余额", "卡内余额", "活期余额", "当前余额")
    }
}
