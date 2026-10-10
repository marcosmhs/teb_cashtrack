package br.com.thatexoticbug.teb_cashtrack.notifications

import android.content.Context

/**
 * Preferências do lançamento automático, guardadas no aparelho. São lidas pelo
 * serviço de notificações (que roda sem o Flutter) e editadas pela tela do app.
 */
class NotificationSettings(context: Context) {
    private val prefs = context.getSharedPreferences("cashtrack_notifications", Context.MODE_PRIVATE)

    /** Capturar notificações dos apps monitorados. */
    var enabled: Boolean
        get() = prefs.getBoolean(KEY_ENABLED, true)
        set(value) = prefs.edit().putBoolean(KEY_ENABLED, value).apply()

    /** Criar lançamentos automaticamente (senão, apenas registra a captura). */
    var autoCreate: Boolean
        get() = prefs.getBoolean(KEY_AUTO_CREATE, true)
        set(value) = prefs.edit().putBoolean(KEY_AUTO_CREATE, value).apply()

    /** Pacotes Android monitorados. */
    var packages: Set<String>
        get() = prefs.getStringSet(KEY_PACKAGES, null)?.toSet() ?: DEFAULT_PACKAGES
        set(value) = prefs.edit().putStringSet(KEY_PACKAGES, value).apply()

    fun toMap(): Map<String, Any> = mapOf(
        "enabled" to enabled,
        "autoCreate" to autoCreate,
        "packages" to packages.sorted(),
    )

    fun update(map: Map<*, *>) {
        (map["enabled"] as? Boolean)?.let { enabled = it }
        (map["autoCreate"] as? Boolean)?.let { autoCreate = it }
        (map["packages"] as? List<*>)?.let { list -> packages = list.filterIsInstance<String>().toSet() }
    }

    companion object {
        private const val KEY_ENABLED = "enabled"
        private const val KEY_AUTO_CREATE = "autoCreate"
        private const val KEY_PACKAGES = "packages"

        /** Samsung Wallet (antigo Samsung Pay). */
        const val SAMSUNG_WALLET = "com.samsung.android.spay"

        val DEFAULT_PACKAGES = setOf(SAMSUNG_WALLET)

        /** Apps cujas notificações são sempre de pagamento. */
        val TRUSTED_PACKAGES = setOf(SAMSUNG_WALLET)
    }
}
