package com.bnyad.app

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.os.Build
import androidx.annotation.RequiresApi
import androidx.health.connect.client.HealthConnectClient
import androidx.health.connect.client.PermissionController
import androidx.health.connect.client.permission.HealthPermission
import androidx.health.connect.client.records.StepsRecord
import androidx.health.connect.client.records.DistanceRecord
import androidx.health.connect.client.request.AggregateRequest
import androidx.health.connect.client.time.TimeRangeFilter
import androidx.lifecycle.lifecycleScope
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.launch
import kotlinx.coroutines.withTimeout
import java.time.Instant

@RequiresApi(28)
class HealthStepBridge(private val activity: FlutterFragmentActivity, flutterEngine: FlutterEngine) {
    private var channel: MethodChannel? = null
    private var pendingPermission: MethodChannel.Result? = null
    private val stepsPermission = HealthPermission.getReadPermission(StepsRecord::class)
    private val distancePermission = HealthPermission.getReadPermission(DistanceRecord::class)
    private val permissionLauncher = activity.registerForActivityResult(
        PermissionController.createRequestPermissionResultContract()
    ) { granted ->
        pendingPermission?.success(stepsPermission in granted)
        pendingPermission = null
    }
    private val timeReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context?, intent: Intent?) {
            channel?.invokeMethod("timeChanged", null)
        }
    }
    private var receiverRegistered = false

    init {
        channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "com.bnyad.app/steps")
        channel?.setMethodCallHandler { call, result ->
            if (call.method == "offlinePreviewAllowed") {
                result.success(offlinePreviewAllowed(activity))
                return@setMethodCallHandler
            }
            activity.lifecycleScope.launch {
                try {
                    val sdk = HealthConnectClient.getSdkStatus(activity)
                    if (call.method == "openSettings") {
                        val intent = if (sdk == HealthConnectClient.SDK_UNAVAILABLE_PROVIDER_UPDATE_REQUIRED)
                            Intent(Intent.ACTION_VIEW, android.net.Uri.parse("market://details?id=com.google.android.apps.healthdata"))
                        else Intent(if (Build.VERSION.SDK_INT >= 34)
                            "android.health.connect.action.HEALTH_HOME_SETTINGS"
                            else "androidx.health.ACTION_HEALTH_CONNECT_SETTINGS")
                        if (Build.VERSION.SDK_INT < 34 && sdk == HealthConnectClient.SDK_AVAILABLE)
                            intent.setPackage("com.google.android.apps.healthdata")
                        activity.startActivity(intent)
                        result.success(null)
                    } else if (call.method == "access") {
                        val permission = if (sdk == HealthConnectClient.SDK_AVAILABLE) {
                            val granted = withTimeout(8000) {
                                HealthConnectClient.getOrCreate(activity).permissionController.getGrantedPermissions()
                            }
                            if (stepsPermission in granted) "granted" else "denied"
                        } else "unknown"
                        result.success(mapOf("availability" to when (sdk) {
                            HealthConnectClient.SDK_AVAILABLE -> "available"
                            HealthConnectClient.SDK_UNAVAILABLE_PROVIDER_UPDATE_REQUIRED -> "installRequired"
                            else -> "unavailable"
                        }, "permission" to permission))
                    } else if (call.method == "requestAccess") {
                        if (sdk != HealthConnectClient.SDK_AVAILABLE || pendingPermission != null) result.success(false)
                        else {
                            pendingPermission = result
                            // Steps are required; distance can be denied independently.
                            permissionLauncher.launch(setOf(stepsPermission, distancePermission))
                        }
                    } else if (call.method == "readDays") {
                        check(sdk == HealthConnectClient.SDK_AVAILABLE)
                        val windows = call.argument<List<Map<String, Any>>>("windows") ?: error("windows")
                        require(windows.isNotEmpty() && windows.size <= 15)
                        val client = HealthConnectClient.getOrCreate(activity)
                        val output = withTimeout(24000) {
                            val permissions = client.permissionController.getGrantedPermissions()
                            if (stepsPermission !in permissions) throw SecurityException()
                            windows.map { window ->
                                val start = Instant.ofEpochMilli((window["start"] as Number).toLong())
                                val end = Instant.ofEpochMilli((window["end"] as Number).toLong())
                                require(!end.isBefore(start) && java.time.Duration.between(start, end).toHours() <= 26)
                                require(start.isAfter(Instant.now().minusSeconds(16 * 86400)) && !end.isAfter(Instant.now().plusSeconds(60)))
                                val metrics = if (distancePermission in permissions)
                                    setOf(StepsRecord.COUNT_TOTAL, DistanceRecord.DISTANCE_TOTAL)
                                else setOf(StepsRecord.COUNT_TOTAL)
                                // No DataOrigin filter: respect native source priorities and
                                // include system steps. Never sum raw phone/watch records.
                                val aggregate = client.aggregate(AggregateRequest(
                                    metrics = metrics,
                                    timeRangeFilter = TimeRangeFilter.between(start, end)
                                ))
                                mapOf("date" to window["date"], "steps" to aggregate[StepsRecord.COUNT_TOTAL],
                                    "distanceMeters" to aggregate[DistanceRecord.DISTANCE_TOTAL]?.inMeters)
                            }
                        }
                        result.success(output)
                    } else result.notImplemented()
                } catch (_: SecurityException) {
                    result.error("health_permission_denied", "Health permission is unavailable or revoked.", null)
                } catch (_: Exception) {
                    if (pendingPermission === result) pendingPermission = null
                    result.error("health_unavailable", "Health data is temporarily unavailable.", null)
                }
            }
        }
        val filter = IntentFilter().apply {
            addAction(Intent.ACTION_TIME_CHANGED)
            addAction(Intent.ACTION_TIMEZONE_CHANGED)
            addAction(Intent.ACTION_DATE_CHANGED)
        }
        if (Build.VERSION.SDK_INT >= 33) activity.registerReceiver(timeReceiver, filter, Context.RECEIVER_NOT_EXPORTED)
        else @Suppress("DEPRECATION") activity.registerReceiver(timeReceiver, filter)
        receiverRegistered = true
    }
    fun dispose() {
        if (receiverRegistered) activity.unregisterReceiver(timeReceiver)
        pendingPermission?.error("health_cancelled", "Health permission request was interrupted.", null)
        pendingPermission = null
        channel?.setMethodCallHandler(null)
    }
}
