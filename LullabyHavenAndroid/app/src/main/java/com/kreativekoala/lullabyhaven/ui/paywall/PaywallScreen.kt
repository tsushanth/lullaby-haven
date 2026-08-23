package com.kreativekoala.lullabyhaven.ui.paywall

import androidx.compose.runtime.Composable
import com.kreativekoala.lullabyhaven.ui.theme.LHAccent
import com.kreativekoala.lullabyhaven.ui.theme.LHAccent2
import com.kreativekoala.paywallkit.models.PaywallFeature
import com.kreativekoala.paywallkit.models.PaywallProduct
import com.kreativekoala.paywallkit.models.PaywallTheme
import com.kreativekoala.paywallkit.view.PaywallView

/**
 * Wraps the shared PaywallKit-Android library rather than building new paywall UI, matching
 * iOS Views/PaywallView.swift (which wraps PaywallKit for iOS).
 *
 * TODO: no RevenueCat/Billing project is wired up for Lullaby Haven yet -- [products] is empty
 * until real product IDs + a BillingClient/RevenueCat integration are added. Do NOT hardcode a
 * RevenueCat project id here without explicit sign-off (see portfolio memory: RC ids are
 * app-specific and must be created/verified per app).
 */
@Composable
fun PaywallScreen(onDismiss: () -> Unit) {
    PaywallView(
        appId = "lullabyhaven",
        appName = "Lullaby Haven Pro",
        features = listOf(
            PaywallFeature(icon = "moon.stars.fill", title = "Full Story Library", description = "All bedtime stories unlocked"),
            PaywallFeature(icon = "waveform", title = "Voice Cloning", description = "Generate lullabies in your own voice"),
            PaywallFeature(icon = "timer", title = "Sleep Timer", description = "Smart timer to fade audio as baby drifts off"),
        ),
        products = emptyList<PaywallProduct>(), // TODO: wire real products once Billing is set up.
        theme = PaywallTheme(accent = LHAccent, accent2 = LHAccent2),
        showWinback = true,
        onPurchase = { _ ->
            // TODO: wire BillingClient/RevenueCat purchase flow.
        },
        onRestore = {
            // TODO: wire BillingClient/RevenueCat restore flow.
        },
        onDismiss = onDismiss
    )
}
