package br.com.thatexoticbug.teb_cashtrack.notifications

import java.util.Locale

/** Compra (ou estorno) identificada no texto de uma notificação. */
data class ParsedPayment(
    val amountCents: Long,
    val merchant: String?,
    /** Últimos 4 dígitos do cartão, quando presentes no texto. */
    val cardHint: String?,
    /** `true` para estornos/reembolsos (lançados como crédito). */
    val isRefund: Boolean,
)

/**
 * Extrai dados de pagamento de notificações em português (Samsung Wallet e apps de bancos).
 *
 * Exemplos reconhecidos:
 * - "Compra de R$ 45,90 APROVADA em PADARIA X para o cartão com final 1234."
 * - "Compra aprovada no cartão final 1234 de R$ 1.234,56 em LOJA Y, às 12:34."
 * - "R$ 45,90 em PADARIA X" (Samsung Wallet)
 */
object NotificationParser {
    private val amountRegex =
        Regex("""(?:R\$|BRL)\s*(\d{1,3}(?:\.\d{3})+,\d{2}|\d+,\d{2})""", RegexOption.IGNORE_CASE)

    private val cardRegex = Regex(
        """(?:final|finalizado em|terminado em|terminação|[•*●∙·xX]{2,})\s*(\d{4})\b""",
        RegexOption.IGNORE_CASE,
    )

    /** Estabelecimento: texto após "em/no/na" até um delimitador ("com" costuma indicar o cartão). */
    private val merchantRegex = Regex(
        """(?:^|\s)(?:em|no|na)\s+(.+?)(?=\s+(?:para\s|no cartão|com\s|às\s|as\s\d|em \d{2}/|dia \d|final\s|[•*●∙·]{2,})|[,;]|\.(?:\s|$)|$)""",
        RegexOption.IGNORE_CASE,
    )

    private val purchaseKeywords = listOf(
        "compra", "pagamento", "pago", "transação", "transacao", "aprovad", "débito", "debito", "gasto",
    )
    private val refundKeywords = listOf("estorno", "estornad", "reembolso", "devolu", "cancelad")
    private val nonPurchaseKeywords = listOf("fatura", "boleto", "limite disponível", "limite disponivel")
    private val promoKeywords = listOf("ganhe", "desconto", "cashback", "oferta", "promo", "cupom")
    private val notMerchantPrefixes = listOf("cartão", "cartao", "seu ", "sua ", "o cartão", "final", "r$")

    /**
     * @param trustedSource `true` para apps cujas notificações são sempre pagamentos
     *   (ex.: Samsung Wallet); nesse caso não exige palavras como "compra".
     */
    fun parse(title: String?, text: String?, trustedSource: Boolean = false): ParsedPayment? {
        val full = listOfNotNull(title, text).joinToString(" ").replace(Regex("\\s+"), " ").trim()
        if (full.isEmpty()) return null
        val lower = full.lowercase(Locale.ROOT)

        val amountMatch = amountRegex.find(full) ?: return null
        val amountCents = amountMatch.groupValues[1].replace(".", "").replace(",", "").toLongOrNull()
        if (amountCents == null || amountCents <= 0) return null

        val isRefund = refundKeywords.any { lower.contains(it) }
        val isPurchase = purchaseKeywords.any { lower.contains(it) }
        // Fatura fechada, boleto, aviso de limite etc. não são compras.
        if (!isPurchase && !isRefund && nonPurchaseKeywords.any { lower.contains(it) }) return null
        if (!isPurchase && !isRefund) {
            if (!trustedSource || promoKeywords.any { lower.contains(it) }) return null
        }

        val cardHint = cardRegex.find(full)?.groupValues?.get(1)
        val merchant = findMerchant(text ?: full, amountMatch.value)
        // Fonte confiável sem palavra de compra: exige ao menos estabelecimento ou cartão.
        if (!isPurchase && !isRefund && merchant == null && cardHint == null) return null

        return ParsedPayment(amountCents, merchant, cardHint, isRefund)
    }

    private fun findMerchant(text: String, amountText: String): String? {
        // Prioriza o trecho após o valor ("R$ 10,00 em LOJA"); senão, procura no texto todo.
        val afterAmount = text.substringAfter(amountText, missingDelimiterValue = "")
        val candidates = listOf(afterAmount, text).filter { it.isNotBlank() }
        for (source in candidates) {
            for (match in merchantRegex.findAll(source)) {
                val raw = match.groupValues[1].trim().trimEnd('.', '!', ',')
                val lower = raw.lowercase(Locale.ROOT)
                if (raw.length < 2 || raw.contains("R$")) continue
                if (notMerchantPrefixes.any { lower.startsWith(it) }) continue
                return prettify(raw)
            }
        }
        return null
    }

    /** "PADARIA PAO QUENTE" → "Padaria Pao Quente"; mantém textos já em caixa mista. */
    private fun prettify(value: String): String {
        val collapsed = value.replace(Regex("\\s+"), " ").take(80)
        if (collapsed != collapsed.uppercase(Locale.ROOT)) return collapsed
        return collapsed.lowercase(Locale.ROOT).split(" ").joinToString(" ") { word ->
            word.replaceFirstChar { it.titlecase(Locale.ROOT) }
        }
    }
}
