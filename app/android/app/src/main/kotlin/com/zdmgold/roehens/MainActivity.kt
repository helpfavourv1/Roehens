package com.zdmgold.roehens

import android.app.PictureInPictureParams
import android.content.pm.PackageManager
import android.os.Build
import android.util.Rational
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private var networkChannel: MulticastLockChannel? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        networkChannel = MulticastLockChannel(this).also {
            it.register(flutterEngine.dartExecutor.binaryMessenger)
        }
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, PIP_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "isSupported" -> result.success(isPipSupported())
                    "enter" -> result.success(enterPip())
                    "info" -> result.success(deviceInfo())
                    else -> result.notImplemented()
                }
            }
    }

    override fun onDestroy() {
        networkChannel?.release()
        super.onDestroy()
    }

    private fun isPipSupported(): Boolean {
        return Build.VERSION.SDK_INT >= Build.VERSION_CODES.O &&
            packageManager.hasSystemFeature(PackageManager.FEATURE_PICTURE_IN_PICTURE)
    }

    private fun deviceInfo(): String {
        val activityManager = getSystemService(ACTIVITY_SERVICE) as android.app.ActivityManager
        return "sdk=${Build.VERSION.SDK_INT} model=${Build.MODEL} " +
            "lowRam=${activityManager.isLowRamDevice} " +
            "pipFeature=${packageManager.hasSystemFeature(PackageManager.FEATURE_PICTURE_IN_PICTURE)}"
    }

    private fun enterPip(): Boolean {
        if (!isPipSupported()) return false
        return try {
            val params = PictureInPictureParams.Builder()
                .setAspectRatio(Rational(16, 9))
                .build()
            enterPictureInPictureMode(params)
        } catch (e: IllegalStateException) {
            false
        }
    }

    companion object {
        private const val PIP_CHANNEL = "roehens/pip"
    }
}
