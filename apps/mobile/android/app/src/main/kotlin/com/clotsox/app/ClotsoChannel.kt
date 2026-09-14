package com.clotsox.app

import android.content.Context
import android.provider.Settings
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.security.MessageDigest
import java.util.UUID

/**
 * Bridge contract only. Register this class from MainActivity after `flutter create .`.
 * Shizuku integration must whitelist fixed profile IDs; it must never accept shell text
 * supplied by Flutter or a remote server.
 */
class ClotsoChannel(private val context: Context) : MethodChannel.MethodCallHandler {
    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "installationHash" -> result.success(installationHash())
            "status" -> result.success(mapOf("available" to false, "authorized" to false))
            "requestAccess" -> result.error("SHIZUKU_NOT_LINKED", "Add the official Shizuku dependency and permission flow before enabling this action.", null)
            "applyProfile" -> result.error("SHIZUKU_NOT_LINKED", "No system profile is available until native commands are independently reviewed.", null)
            else -> result.notImplemented()
        }
    }

    private fun installationHash(): String {
        val preferences = context.getSharedPreferences("clotso_identity", Context.MODE_PRIVATE)
        val installId = preferences.getString("install_id", null) ?: UUID.randomUUID().toString().also {
            preferences.edit().putString("install_id", it).apply()
        }
        // Android ID is used only as a local salt; raw identifiers never leave this method.
        val androidId = Settings.Secure.getString(context.contentResolver, Settings.Secure.ANDROID_ID) ?: "unknown"
        val bytes = MessageDigest.getInstance("SHA-256").digest("$installId:$androidId".toByteArray())
        return bytes.joinToString("") { "%02x".format(it) }
    }
}
