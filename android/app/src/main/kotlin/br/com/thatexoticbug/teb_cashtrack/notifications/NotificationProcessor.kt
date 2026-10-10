package br.com.thatexoticbug.teb_cashtrack.notifications

import android.content.Context
import android.util.Log
import com.google.firebase.FirebaseApp
import com.google.firebase.Timestamp
import com.google.firebase.auth.FirebaseAuth
import com.google.firebase.firestore.DocumentSnapshot
import com.google.firebase.firestore.FirebaseFirestore
import java.security.MessageDigest
import java.util.Date
import java.util.Locale

/**
 * Transforma uma notificação de pagamento em lançamento no Firestore
 * (`users/{uid}/transactions`) e registra a captura em `users/{uid}/notification_captures`.
 * Usa a sessão do Firebase Auth do próprio app; sem usuário logado, nada é gravado.
 */
object NotificationProcessor {
    private const val TAG = "CashTrackNotif"

    fun process(context: Context, pkg: String, title: String?, text: String?, postedAt: Long) {
        if (FirebaseApp.getApps(context).isEmpty()) FirebaseApp.initializeApp(context)
        val uid = FirebaseAuth.getInstance().currentUser?.uid
        if (uid == null) {
            Log.i(TAG, "Notificação ignorada: nenhum usuário logado")
            return
        }

        val settings = NotificationSettings(context)
        val trusted = pkg in NotificationSettings.TRUSTED_PACKAGES
        val parsed = NotificationParser.parse(title, text, trusted)
        // Mesmo conteúdo no mesmo minuto = mesma notificação (reposts/atualizações não duplicam).
        val captureId = sha1("$pkg|$title|$text|${postedAt / 60_000}")
        val userDoc = FirebaseFirestore.getInstance().collection("users").document(uid)

        val capture = hashMapOf<String, Any?>(
            "package" to pkg,
            "title" to title,
            "text" to text,
            "postedAt" to Timestamp(Date(postedAt)),
            "amountCents" to parsed?.amountCents,
            "merchant" to parsed?.merchant,
            "cardHint" to parsed?.cardHint,
            "isRefund" to parsed?.isRefund,
        )

        fun saveCapture(status: String, transactionId: String? = null, accountId: String? = null) {
            capture["status"] = status
            capture["transactionId"] = transactionId
            capture["accountId"] = accountId
            userDoc.collection("notification_captures").document(captureId).set(capture)
                .addOnFailureListener { Log.w(TAG, "Falha ao registrar captura", it) }
        }

        if (parsed == null) return saveCapture("unparsed")
        if (!settings.autoCreate) return saveCapture("auto_disabled")

        // Busca as contas (usa o cache local quando estiver sem internet).
        userDoc.collection("accounts").get()
            .addOnSuccessListener { snapshot ->
                val account = chooseAccount(snapshot.documents, parsed, "$title $text")
                if (account == null) return@addOnSuccessListener saveCapture("unmatched_account")

                val transactionId = "notif_$captureId"
                val transaction = hashMapOf<String, Any?>(
                    "date" to Timestamp(Date(postedAt)),
                    "accountId" to account.id,
                    "amountCents" to parsed.amountCents,
                    "details" to parsed.merchant,
                    "tagId" to null,
                    "type" to if (parsed.isRefund) "credit" else "debit",
                    "source" to "notification",
                )
                userDoc.collection("transactions").document(transactionId).set(transaction)
                    .addOnFailureListener { Log.w(TAG, "Falha ao gravar lançamento", it) }
                saveCapture("created", transactionId, account.id)
            }
            .addOnFailureListener {
                Log.w(TAG, "Falha ao carregar contas", it)
                saveCapture("error")
            }
    }

    /**
     * Escolhe a conta do lançamento, nesta ordem:
     * 1. conta ativa cujo "identificador nas notificações" bate com o final do cartão ou aparece no texto;
     * 2. o único cartão de crédito ativo;
     * 3. o meio de pagamento principal.
     */
    internal fun chooseAccount(
        accounts: List<DocumentSnapshot>,
        parsed: ParsedPayment,
        fullText: String,
    ): DocumentSnapshot? {
        val active = accounts.filter { it.getBoolean("active") != false }
        val text = fullText.lowercase(Locale.ROOT)

        active.firstOrNull { doc ->
            val match = doc.getString("notificationMatch")?.trim()?.lowercase(Locale.ROOT)
            !match.isNullOrEmpty() && (match == parsed.cardHint || text.contains(match))
        }?.let { return it }

        val cards = active.filter { it.getString("type") == "creditCard" }
        if (cards.size == 1) return cards.first()

        return active.firstOrNull { it.getBoolean("isDefault") == true }
    }

    private fun sha1(value: String): String {
        val digest = MessageDigest.getInstance("SHA-1").digest(value.toByteArray())
        return digest.joinToString("") { "%02x".format(it) }.take(24)
    }
}
