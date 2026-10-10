package br.com.thatexoticbug.teb_cashtrack.notifications

import android.app.Notification
import android.service.notification.NotificationListenerService
import android.service.notification.StatusBarNotification
import android.util.Log

/**
 * Recebe as notificações do sistema (após o usuário conceder "Acesso a notificações")
 * e repassa ao [NotificationProcessor] apenas as dos apps monitorados.
 * O Android mantém este serviço ativo mesmo com o app fechado.
 */
class CardNotificationListener : NotificationListenerService() {
    /** Últimas notificações tratadas, para ignorar atualizações repetidas da mesma notificação. */
    private val recent = ArrayDeque<String>()

    override fun onNotificationPosted(sbn: StatusBarNotification) {
        try {
            val settings = NotificationSettings(this)
            if (!settings.enabled || sbn.packageName !in settings.packages) return

            val notification = sbn.notification
            if (notification.flags and Notification.FLAG_GROUP_SUMMARY != 0) return

            val extras = notification.extras
            val title = extras.getCharSequence(Notification.EXTRA_TITLE)?.toString()
            val text = (extras.getCharSequence(Notification.EXTRA_BIG_TEXT)
                ?: extras.getCharSequence(Notification.EXTRA_TEXT))?.toString()
            if (title.isNullOrBlank() && text.isNullOrBlank()) return

            val dedupKey = "${sbn.packageName}|$title|$text"
            if (dedupKey in recent) return
            recent.addLast(dedupKey)
            if (recent.size > 20) recent.removeFirst()

            val postedAt = notification.`when`.takeIf { it > 0 } ?: sbn.postTime
            NotificationProcessor.process(applicationContext, sbn.packageName, title, text, postedAt)
        } catch (e: Exception) {
            // Nunca derrubar o serviço por causa de uma notificação inesperada.
            Log.e("CashTrackNotif", "Erro ao processar notificação", e)
        }
    }
}
