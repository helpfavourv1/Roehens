package com.zdmgold.roehens

import android.content.Context
import android.content.Intent
import android.net.Uri
import android.net.wifi.WifiManager
import android.provider.Settings
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/**
 * Network helpers that only Android can provide: the Wi-Fi multicast lock that
 * some phones need to deliver discovery replies, the Wi-Fi gateway address, and
 * a shortcut to this app's system settings page.
 */
class MulticastLockChannel(private val context: Context) : MethodChannel.MethodCallHandler {
    private var lock: WifiManager.MulticastLock? = null

    fun register(messenger: BinaryMessenger) {
        MethodChannel(messenger, CHANNEL).setMethodCallHandler(this)
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "acquireMulticastLock" -> result.success(acquire())
            "releaseMulticastLock" -> {
                release()
                result.success(null)
            }
            "gateway" -> result.success(gateway())
            "openAppSettings" -> result.success(openAppSettings())
            else -> result.notImplemented()
        }
    }

    private fun wifi(): WifiManager? {
        return context.applicationContext.getSystemService(Context.WIFI_SERVICE) as? WifiManager
    }

    private fun acquire(): Boolean {
        val manager = wifi() ?: return false
        val existing = lock
        if (existing != null && existing.isHeld) return true
        return try {
            val created = manager.createMulticastLock("roehens-discovery")
            created.setReferenceCounted(false)
            created.acquire()
            lock = created
            true
        } catch (e: SecurityException) {
            false
        }
    }

    fun release() {
        val held = lock
        if (held != null && held.isHeld) held.release()
        lock = null
    }

    @Suppress("DEPRECATION")
    private fun gateway(): String? {
        val info = wifi()?.dhcpInfo ?: return null
        val raw = info.gateway
        if (raw == 0) return null
        return "${raw and 0xff}.${(raw shr 8) and 0xff}.${(raw shr 16) and 0xff}.${(raw shr 24) and 0xff}"
    }

    private fun openAppSettings(): Boolean {
        return try {
            val intent = Intent(
                Settings.ACTION_APPLICATION_DETAILS_SETTINGS,
                Uri.parse("package:${context.packageName}")
            )
            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            context.startActivity(intent)
            true
        } catch (e: Exception) {
            false
        }
    }

    companion object {
        const val CHANNEL = "roehens/network"
    }
}
