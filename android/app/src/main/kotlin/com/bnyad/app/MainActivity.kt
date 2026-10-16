package com.bnyad.app

import android.os.Build
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterFragmentActivity() {
    private var healthBridge: HealthStepBridge? = null
    private var unsupportedChannel: MethodChannel? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        // Keep BNYAD's existing API 24 support. Never load Health Connect's
        // API-26+ classes on an unsupported device (HC itself requires API 28).
        if (Build.VERSION.SDK_INT >= 28) {
            healthBridge = HealthStepBridge(this, flutterEngine)
        } else {
            unsupportedChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "com.bnyad.app/steps")
            unsupportedChannel?.setMethodCallHandler { call, result ->
                when (call.method) {
                    "access" -> result.success(mapOf("availability" to "unavailable", "permission" to "unknown"))
                    "requestAccess" -> result.success(false)
                    "readDays" -> result.success(emptyList<Any>())
                    else -> result.notImplemented()
                }
            }
        }
    }
    override fun onDestroy() {
        if (Build.VERSION.SDK_INT >= 28) healthBridge?.dispose()
        unsupportedChannel?.setMethodCallHandler(null)
        super.onDestroy()
    }
}
