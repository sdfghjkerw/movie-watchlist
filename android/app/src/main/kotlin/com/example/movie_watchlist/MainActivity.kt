package com.example.movie_watchlist

import android.os.BatteryManager
import android.os.Build
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val deviceChannel = "movie_watchlist/device"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, deviceChannel)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "getDeviceStatus" -> result.success(readDeviceStatus())
                    else -> result.notImplemented()
                }
            }
    }

    private fun readDeviceStatus(): Map<String, Any?> {
        val batteryManager = getSystemService(BATTERY_SERVICE) as BatteryManager
        val level = batteryManager.getIntProperty(BatteryManager.BATTERY_PROPERTY_CAPACITY)
        val isCharging = Build.VERSION.SDK_INT >= Build.VERSION_CODES.M &&
            batteryManager.isCharging

        return mapOf(
            "deviceModel" to "${Build.MANUFACTURER} ${Build.MODEL}".trim(),
            "androidVersion" to Build.VERSION.RELEASE,
            "batteryLevel" to level.takeIf { it in 0..100 },
            "isCharging" to isCharging,
        )
    }
}
