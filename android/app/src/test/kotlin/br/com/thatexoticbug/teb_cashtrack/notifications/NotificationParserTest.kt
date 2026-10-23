package br.com.thatexoticbug.teb_cashtrack.notifications

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test

class NotificationParserTest {
    @Test
    fun nubankStyle() {
        val p = NotificationParser.parse(
            "Compra aprovada",
            "Compra de R$ 45,90 APROVADA em PADARIA PAO QUENTE para o cartão com final 1234.",
        )!!
        assertEquals(4590L, p.amountCents)
        assertEquals("Padaria Pao Quente", p.merchant)
        assertEquals("1234", p.cardHint)
        assertFalse(p.isRefund)
    }

    @Test
    fun itauStyleWithThousands() {
        val p = NotificationParser.parse(
            "Itaú",
            "Compra aprovada no cartão final 9876 de R$ 1.234,56 em Magazine Luiza, às 12:34.",
        )!!
        assertEquals(123456L, p.amountCents)
        assertEquals("Magazine Luiza", p.merchant)
        assertEquals("9876", p.cardHint)
    }

    @Test
    fun samsungWalletShortText() {
        val p = NotificationParser.parse("Samsung Wallet", "R$12,00 em UBER TRIP", trustedSource = true)!!
        assertEquals(1200L, p.amountCents)
        assertEquals("Uber Trip", p.merchant)
        assertNull(p.cardHint)
    }

    @Test
    fun maskedCardDigits() {
        val p = NotificationParser.parse(
            "Pagamento realizado",
            "Pagamento de R$ 8,50 com Visa •••• 4321",
        )!!
        assertEquals(850L, p.amountCents)
        assertEquals("4321", p.cardHint)
        assertNull(p.merchant)
    }

    @Test
    fun refundIsDetected() {
        val p = NotificationParser.parse("Estorno", "Estorno de R$ 30,00 da compra em LOJA X")!!
        assertTrue(p.isRefund)
        assertEquals(3000L, p.amountCents)
    }

    @Test
    fun ignoresInvoiceAndLimitNotices() {
        assertNull(NotificationParser.parse("Fatura fechada", "Sua fatura de R$ 1.500,00 fechou"))
        assertNull(NotificationParser.parse("Aviso", "Seu limite disponível é de R$ 2.000,00"))
    }

    @Test
    fun requiresPurchaseWordsForUntrustedApps() {
        assertNull(NotificationParser.parse("Promoção", "Ganhe R$ 10,00 de desconto"))
        assertNull(NotificationParser.parse("Promoção", "Ganhe R$ 10,00 de desconto", trustedSource = true))
        assertNotNull(NotificationParser.parse("Wallet", "R$ 10,00 em LOJA", trustedSource = true))
    }

    @Test
    fun ignoresTextWithoutAmount() {
        assertNull(NotificationParser.parse("Samsung Wallet", "Cartão adicionado com sucesso", trustedSource = true))
        assertNull(NotificationParser.parse(null, null))
    }
}
