package com.bnyad.app

import android.os.Build
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

// Both native compilation and the installed ID must authorize fixture access.
internal fun offlinePreviewAllowed(context: android.content.Context): Boolean =
    BuildConfig.DEBUG && BuildConfig.BNYAD_OFFLINE_PREVIEW && context.packageName == "com.bnyad.app.dev"

internal fun localBackendAllowed(context: android.content.Context): Boolean =
    BuildConfig.DEBUG && BuildConfig.BNYAD_LOCAL_BACKEND && context.packageName == "com.bnyad.app.dev"

class MainActivity : FlutterFragmentActivity() {
    private var localeChannel: MethodChannel? = null
    private var healthBridge: HealthStepBridge? = null
    private var unsupportedChannel: MethodChannel? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        localeChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "com.bnyad.app/localization").also { channel ->
            channel.setMethodCallHandler { call, result ->
                if (call.method == "setLanguage" && call.arguments in listOf("en", "ar", "ku", "ckb")) {
                    getSharedPreferences("bnyad_localization", MODE_PRIVATE).edit().putString("language", call.arguments as String).apply()
                    result.success(null)
                } else result.notImplemented()
            }
        }
        // Keep BNYAD's existing API 24 support. Never load Health Connect's
        // API-26+ classes on an unsupported device (HC itself requires API 28).
        if (Build.VERSION.SDK_INT >= 28) {
            healthBridge = HealthStepBridge(this, flutterEngine)
        } else {
            unsupportedChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "com.bnyad.app/steps")
            unsupportedChannel?.setMethodCallHandler { call, result ->
                when (call.method) {
                    "offlinePreviewAllowed" -> result.success(offlinePreviewAllowed(this))
                    "localBackendAllowed" -> result.success(localBackendAllowed(this))
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
        localeChannel?.setMethodCallHandler(null)
        super.onDestroy()
    }
}
