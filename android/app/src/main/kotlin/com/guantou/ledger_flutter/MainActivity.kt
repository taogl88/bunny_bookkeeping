package com.guantou.ledger_flutter

import android.util.Log
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.android.FlutterActivity
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            CHANNEL_NAME
        ).setMethodCallHandler { call, result ->
            Log.d(TAG, "[MainActivity] MethodChannel call: ${call.method}")
            when (call.method) {
                "ensurePermissions" -> SmsPlugin.ensurePermissions(this, result)
                "getPendingTransactions" -> {
                    result.success(SmsPlugin.getPendingTransactions(this).toString())
                }
                else -> result.notImplemented()
            }
        }
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray
    ) {
        if (SmsPlugin.onRequestPermissionsResult(this, requestCode, grantResults)) {
            return
        }
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
    }

    companion object {
        private const val TAG = "LedgerSms"
        private const val CHANNEL_NAME = "ledger_flutter/sms"
    }
}
