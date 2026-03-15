//
//  PaywallView.swift
//  LullabyHaven
//
//  Premium subscription paywall
//

import SwiftUI
import StoreKit

struct PaywallView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(StoreKitManager.self) private var storeKit

    @State private var selectedProduct: Product?
    @State private var isPurchasing = false
    @State private var errorMessage: String?
    @State private var showError = false

    private let features: [(String, String)] = [
        ("waveform.path.ecg", "50+ Premium Sleep Sounds"),
        ("slider.horizontal.3", "Mix Up to 5 Sounds"),
        ("moon.stars.fill", "All Night Timer (8 hours)"),
        ("chart.line.uptrend.xyaxis", "Sleep Analytics"),
        ("wand.and.stars", "Gentle Fade-Out"),
        ("heart.fill", "Unlimited Favorites"),
    ]

    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                LinearGradient(
                    colors: [Color(hex: "#0d1117"), Color(hex: "#1a1f2e")],
                    startPoint: .top, endPoint: .bottom
                )
                .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 28) {
                        // Header
                        paywallHeader

                        // Features
                        featureList

                        // Products
                        productPicker

                        // CTA
                        ctaSection

                        // Footer
                        paywallFooter
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 40)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.white.opacity(0.5))
                    }
                }
            }
        }
        .alert("Purchase Error", isPresented: $showError) {
            Button("OK") {}
        } message: {
            Text(errorMessage ?? "Something went wrong.")
        }
        .task {
            if storeKit.allProducts.isEmpty {
                await storeKit.loadProducts()
            }
            selectedProduct = storeKit.subscriptions.first(where: { $0.isPopular }) ?? storeKit.subscriptions.last
        }
    }

    // MARK: - Header
    private var paywallHeader: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.lhAccent.opacity(0.2))
                    .frame(width: 90, height: 90)
                Image(systemName: "moon.stars.fill")
                    .font(.system(size: 44))
                    .foregroundStyle(Color.lhAccent)
            }
            .padding(.top, 8)

            Text("Lullaby Haven\nPremium")
                .font(.system(size: 30, weight: .bold))
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)

            Text("Everything your baby needs for\nthe perfect night's sleep")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.7))
                .multilineTextAlignment(.center)
        }
    }

    // MARK: - Features
    private var featureList: some View {
        VStack(spacing: 10) {
            ForEach(features, id: \.0) { icon, text in
                HStack(spacing: 12) {
                    Image(systemName: icon)
                        .font(.body)
                        .foregroundStyle(Color.lhAccent)
                        .frame(width: 24)
                    Text(text)
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.9))
                    Spacer()
                    Image(systemName: "checkmark")
                        .font(.caption.bold())
                        .foregroundStyle(.green)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(.white.opacity(0.05))
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }
        }
    }

    // MARK: - Product Picker
    @ViewBuilder
    private var productPicker: some View {
        if storeKit.isLoading {
            ProgressView()
                .tint(Color.lhAccent)
                .padding()
        } else if storeKit.subscriptions.isEmpty {
            Text("Products unavailable")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.5))
        } else {
            VStack(spacing: 10) {
                ForEach(storeKit.subscriptions) { product in
                    ProductCard(
                        product: product,
                        isSelected: selectedProduct?.id == product.id
                    ) {
                        selectedProduct = product
                    }
                }
                // Lifetime if available
                ForEach(storeKit.nonConsumables) { product in
                    ProductCard(product: product, isSelected: selectedProduct?.id == product.id) {
                        selectedProduct = product
                    }
                }
            }
        }
    }

    // MARK: - CTA
    private var ctaSection: some View {
        VStack(spacing: 12) {
            Button {
                Task { await purchase() }
            } label: {
                ZStack {
                    if isPurchasing {
                        ProgressView().tint(.white)
                    } else {
                        Text(selectedProduct.map { "Start for \($0.displayPrice)" } ?? "Subscribe")
                            .font(.headline)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.lhAccent)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .disabled(selectedProduct == nil || isPurchasing)

            Button("Restore Purchases") {
                Task { await storeKit.restorePurchases() }
            }
            .font(.footnote)
            .foregroundStyle(.white.opacity(0.5))
        }
    }

    // MARK: - Footer
    private var paywallFooter: some View {
        VStack(spacing: 6) {
            if let product = selectedProduct, let label = product.savingsLabel {
                Text(label)
                    .font(.caption.bold())
                    .foregroundStyle(Color.lhGold)
            }
            HStack(spacing: 16) {
                Link("Terms", destination: URL(string: "https://appfactory.app/terms")!)
                Link("Privacy", destination: URL(string: "https://appfactory.app/privacy")!)
            }
            .font(.caption)
            .foregroundStyle(.white.opacity(0.35))
        }
    }

    // MARK: - Purchase
    private func purchase() async {
        guard let product = selectedProduct else { return }
        isPurchasing = true
        defer { isPurchasing = false }
        do {
            _ = try await storeKit.purchase(product)
            if storeKit.isPremium { dismiss() }
        } catch StoreKitError.userCancelled {
            // no-op
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }
}

// MARK: - Product Card
struct ProductCard: View {
    let product: Product
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text(product.displayName)
                            .font(.subheadline.bold())
                            .foregroundStyle(.white)
                        if product.isPopular {
                            Text("POPULAR")
                                .font(.system(size: 9, weight: .black))
                                .foregroundStyle(.black)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.lhGold)
                                .clipShape(Capsule())
                        }
                    }
                    if let label = product.savingsLabel {
                        Text(label)
                            .font(.caption)
                            .foregroundStyle(Color.lhGold)
                    }
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text(product.displayPrice)
                        .font(.headline.bold())
                        .foregroundStyle(.white)
                    Text(product.periodLabel)
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.6))
                }
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(isSelected ? Color.lhAccent : .white.opacity(0.3))
                    .padding(.leading, 8)
            }
            .padding(14)
            .background(isSelected ? Color.lhAccent.opacity(0.2) : .white.opacity(0.05))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.lhAccent : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Color Hex
extension Color {
    init(hex: String) {
        let scanner = Scanner(string: hex.hasPrefix("#") ? String(hex.dropFirst()) : hex)
        var rgb: UInt64 = 0
        scanner.scanHexInt64(&rgb)
        let r = Double((rgb >> 16) & 0xFF) / 255
        let g = Double((rgb >> 8) & 0xFF) / 255
        let b = Double(rgb & 0xFF) / 255
        self.init(red: r, green: g, blue: b)
    }
}
