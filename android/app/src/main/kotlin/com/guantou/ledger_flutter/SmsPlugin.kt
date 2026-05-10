package com.guantou.ledger_flutter

import android.Manifest
import android.app.Activity
import android.content.Context
import android.content.SharedPreferences
import android.content.pm.PackageManager
import android.os.Build
import android.util.Log
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.plugin.common.MethodChannel
import org.json.JSONArray
import org.json.JSONObject

object SmsPlugin {
    private const val requestCode = 4517
    private const val tag = "LedgerSms"

    const val prefName = "LedgerSmsPrefs"
    private const val keyPendingTx = "pending_transactions"

    private var pendingPermissionResult: MethodChannel.Result? = null

    private fun requiredPermissions(): Array<String> {
        val permissions = mutableListOf(
            Manifest.permission.RECEIVE_SMS,
            Manifest.permission.READ_SMS,
        )
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            permissions.add(Manifest.permission.POST_NOTIFICATIONS)
        }
        return permissions.toTypedArray()
    }

    private fun allPermissionsGranted(context: Context): Boolean {
        return requiredPermissions().all { permission ->
            ContextCompat.checkSelfPermission(context, permission) == PackageManager.PERMISSION_GRANTED
        }
    }

    fun ensurePermissions(activity: Activity, result: MethodChannel.Result) {
        val permissionStates = requiredPermissions().joinToString { permission ->
            val granted = ContextCompat.checkSelfPermission(activity, permission) ==
                PackageManager.PERMISSION_GRANTED
            "$permission=$granted"
        }
        Log.d(tag, "[SmsPlugin] ensurePermissions: $permissionStates")
        if (allPermissionsGranted(activity)) {
            Log.d(tag, "[SmsPlugin] ensurePermissions: all granted")
            result.success(true)
            return
        }
        pendingPermissionResult = result
        Log.d(tag, "[SmsPlugin] ensurePermissions: requesting permissions")
        ActivityCompat.requestPermissions(activity, requiredPermissions(), requestCode)
    }

    fun onRequestPermissionsResult(
        activity: Activity,
        requestCode: Int,
        grantResults: IntArray
    ): Boolean {
        if (requestCode != SmsPlugin.requestCode) {
            return false
        }
        val granted = grantResults.isNotEmpty() &&
            grantResults.all { it == PackageManager.PERMISSION_GRANTED } &&
            allPermissionsGranted(activity)
        Log.d(tag, "[SmsPlugin] onRequestPermissionsResult: granted=$granted, results=${grantResults.joinToString()}")
        pendingPermissionResult?.success(granted)
        pendingPermissionResult = null
        return true
    }

    fun getPendingTransactions(context: Context): JSONArray {
        val prefs = context.getSharedPreferences(prefName, Context.MODE_PRIVATE)
        val json = prefs.getString(keyPendingTx, "[]") ?: "[]"
        val array = JSONArray(json)
        Log.d(tag, "[SmsPlugin] getPendingTransactions: count=${array.length()}, payload=$json")
        prefs.edit().putString(keyPendingTx, "[]").apply()
        return array
    }

    fun appendPendingTransaction(context: Context, tx: JSONObject) {
        val prefs = context.getSharedPreferences(prefName, Context.MODE_PRIVATE)
        val json = prefs.getString(keyPendingTx, "[]") ?: "[]"
        val array = JSONArray(json)
        array.put(tx)
        prefs.edit().putString(keyPendingTx, array.toString()).apply()
        Log.d(tag, "[SmsPlugin] appendPendingTransaction: count=${array.length()}, tx=$tx")
    }
}
