package com.masterdaniels.matrixtodo

import android.content.Intent
import android.net.Uri
import android.os.Build
import android.provider.Settings
import android.util.Log
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/**
 * Plugin-only notification delivery (flutter_local_notifications owns
 * channels, schedules and reboot receivers declared in the manifest).
 *
 * The single custom channel here is `matrix_todo/system`, serving the
 * OEM-resilience help screen: vendor detection + settings intents (battery
 * optimization, app info, app notifications). It never requests
 * exemptions directly (Play policy).
 */
class MainActivity : FlutterActivity() {
	override fun onCreate(savedInstanceState: android.os.Bundle?) {
		super.onCreate(savedInstanceState)
		if (isAlarmOrNotificationIntent(intent)) {
			configureLockscreenFlags(true)
		} else {
			configureLockscreenFlags(false)
		}
		if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
			splashScreen.setOnExitAnimationListener { splashScreenView ->
				splashScreenView.remove()
			}
		}
	}

	override fun onNewIntent(intent: Intent) {
		super.onNewIntent(intent)
		if (isAlarmOrNotificationIntent(intent)) {
			configureLockscreenFlags(true)
		}
	}

	private fun isAlarmOrNotificationIntent(intent: Intent?): Boolean {
		if (intent == null) return false
		val isLauncher = Intent.ACTION_MAIN == intent.action &&
				intent.categories?.contains(Intent.CATEGORY_LAUNCHER) == true
		if (isLauncher && !intent.hasExtra("notification_id") && !intent.hasExtra("payload")) {
			return false
		}
		return intent.hasExtra("notification_id") ||
				intent.hasExtra("payload") ||
				intent.hasExtra("action_id") ||
				(intent.action != null && intent.action != Intent.ACTION_MAIN)
	}

	private fun configureLockscreenFlags(show: Boolean) {
		if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O_MR1) {
			setShowWhenLocked(show)
			setTurnScreenOn(show)
		} else {
			@Suppress("DEPRECATION")
			if (show) {
				window.addFlags(
					android.view.WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED or
					android.view.WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON
				)
			} else {
				window.clearFlags(
					android.view.WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED or
					android.view.WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON
				)
			}
		}
	}

	override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
		super.configureFlutterEngine(flutterEngine)
		MethodChannel(
			flutterEngine.dartExecutor.binaryMessenger,
			"matrix_todo/system"
		).setMethodCallHandler { call, result ->
			when (call.method) {
				"setShowWhenLocked" -> {
					val enabled = call.argument<Boolean>("enabled") ?: false
					configureLockscreenFlags(enabled)
					result.success(true)
				}
				"getManufacturer" -> {
					result.success(Build.MANUFACTURER ?: "")
				}
				"openBatteryOptimizationSettings" -> {
					try {
						val intent = Intent(Settings.ACTION_IGNORE_BATTERY_OPTIMIZATION_SETTINGS)
						intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
						startActivity(intent)
						result.success(true)
					} catch (e: Exception) {
						Log.w("MainActivity", "battery settings intent failed: $e")
						openAppDetailsFallback(result)
					}
				}
				"openAppDetailsSettings" -> {
					openAppDetailsFallback(result)
				}
				"openAppNotificationSettings" -> {
					openAppNotificationSettings(result)
				}
				"minimize" -> {
					moveTaskToBack(true)
					result.success(true)
				}
				else -> result.notImplemented()
			}
		}
	}

	private fun openAppDetailsFallback(result: MethodChannel.Result) {
		try {
			val intent = Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS)
			intent.data = Uri.parse("package:$packageName")
			intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
			startActivity(intent)
			result.success(true)
		} catch (e: Exception) {
			Log.e("MainActivity", "app details intent failed: $e")
			result.error("NO_SETTINGS", "Cannot open system settings", null)
		}
	}

	/**
	 * Opens this app's system notification settings (channels, floating
	 * pop-ups, lock-screen, sound). On HyperOS this is where floating
	 * notifications and per-channel importance live. Falls back to app
	 * details on failure / pre-Oreo runtimes.
	 */
	private fun openAppNotificationSettings(result: MethodChannel.Result) {
		try {
			if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
				val intent = Intent(Settings.ACTION_APP_NOTIFICATION_SETTINGS)
				intent.putExtra(Settings.EXTRA_APP_PACKAGE, packageName)
				intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
				startActivity(intent)
				result.success(true)
			} else {
				openAppDetailsFallback(result)
			}
		} catch (e: Exception) {
			Log.w("MainActivity", "notification settings intent failed: $e")
			openAppDetailsFallback(result)
		}
	}
}
