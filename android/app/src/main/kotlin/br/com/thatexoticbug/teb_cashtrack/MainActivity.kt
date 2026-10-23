package br.com.thatexoticbug.teb_cashtrack

import android.annotation.SuppressLint
import android.content.ComponentName
import android.content.Intent
import android.net.Uri
import android.os.PowerManager
import android.provider.Settings
import android.service.notification.NotificationListenerService
import androidx.core.app.NotificationManagerCompat
import br.com.thatexoticbug.teb_cashtrack.notifications.CardNotificationListener
import br.com.thatexoticbug.teb_cashtrack.notifications.NotificationSettings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/** Expõe ao Flutter o controle do lançamento automático por notificações. */
class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            val settings = NotificationSettings(this)
            when (call.method) {
                "getStatus" -> result.success(
                    settings.toMap() + mapOf(
                        "permissionGranted" to hasNotificationAccess(),
                        "ignoringBatteryOptimizations" to isIgnoringBatteryOptimizations(),
                    )
                )
                "saveSettings" -> {
                    (call.arguments as? Map<*, *>)?.let(settings::update)
                    requestRebind()
                    result.success(null)
                }
                "openNotificationAccessSettings" -> {
                    startActivity(Intent(Settings.ACTION_NOTIFICATION_LISTENER_SETTINGS))
                    result.success(null)
                }
                "requestIgnoreBatteryOptimizations" -> {
                    requestIgnoreBatteryOptimizations()
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
    }

    override fun onResume() {
        super.onResume()
        // Garante que o serviço esteja conectado após o usuário conceder a permissão.
        if (hasNotificationAccess()) requestRebind()
    }

    private fun hasNotificationAccess(): Boolean =
        NotificationManagerCompat.getEnabledListenerPackages(this).contains(packageName)

    private fun requestRebind() {
        NotificationListenerService.requestRebind(ComponentName(this, CardNotificationListener::class.java))
    }

    private fun isIgnoringBatteryOptimizations(): Boolean =
        (getSystemService(POWER_SERVICE) as PowerManager).isIgnoringBatteryOptimizations(packageName)

    @SuppressLint("BatteryLife")
    private fun requestIgnoreBatteryOptimizations() {
        val intent = Intent(Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS)
            .setData(Uri.parse("package:$packageName"))
        try {
            startActivity(intent)
        } catch (e: Exception) {
            startActivity(Intent(Settings.ACTION_IGNORE_BATTERY_OPTIMIZATION_SETTINGS))
        }
    }

    companion object {
        const val CHANNEL = "br.com.thatexoticbug.cashtrack/notifications"
    }
}
