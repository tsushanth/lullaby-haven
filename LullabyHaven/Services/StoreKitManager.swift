//
//  StoreKitManager.swift
//  LullabyHaven
//
//  StoreKit 2 implementation for premium subscriptions
//

import Foundation
import StoreKit

// MARK: - Product Identifiers
enum StoreKitProductID: String, CaseIterable {
    case weekly   = "com.appfactory.lullabyhaven.premium.weekly"
    case monthly  = "com.appfactory.lullabyhaven.premium.monthly"
    case yearly   = "com.appfactory.lullabyhaven.premium.yearly"
    case lifetime = "com.appfactory.lullabyhaven.premium.lifetime"

    var displayName: String {
        switch self {
        case .weekly:   return "Weekly"
        case .monthly:  return "Monthly"
        case .yearly:   return "Yearly"
        case .lifetime: return "Lifetime"
        }
    }

    static var allIDs: [String] { allCases.map { $0.rawValue } }
}

// MARK: - Purchase State
enum PurchaseState: Equatable {
    case idle
    case loading
    case purchasing
    case purchased
    case failed(String)
    case pending
    case cancelled
}

// MARK: - StoreKit Error
enum StoreKitError: LocalizedError {
    case productNotFound
    case purchaseFailed(Error)
    case verificationFailed
    case userCancelled
    case pending
    case unknown

    var errorDescription: String? {
        switch self {
        case .productNotFound:        return "Product not found."
        case .purchaseFailed(let e):  return "Purchase failed: \(e.localizedDescription)"
        case .verificationFailed:     return "Purchase verification failed."
        case .userCancelled:          return "Purchase was cancelled."
        case .pending:                return "Purchase is pending approval."
        case .unknown:                return "An unknown error occurred."
        }
    }
}

// MARK: - StoreKit Manager
@MainActor
@Observable
final class StoreKitManager {
    private(set) var subscriptions: [Product] = []
    private(set) var nonConsumables: [Product] = []
    private(set) var allProducts: [Product] = []

    private(set) var purchaseState: PurchaseState = .idle
    private(set) var isLoading: Bool = false
    private(set) var errorMessage: String?

    private(set) var purchasedSubscriptions: Set<String> = []
    private(set) var purchasedNonConsumables: Set<String> = []

    private var updateListenerTask: Task<Void, Error>?

    var hasActiveSubscription: Bool { !purchasedSubscriptions.isEmpty }
    var isPremium: Bool { hasActiveSubscription || !purchasedNonConsumables.isEmpty }

    var currentSubscriptionProductID: String? { purchasedSubscriptions.first }

    init() {
        updateListenerTask = listenForTransactions()
        Task {
            await loadProducts()
            await updatePurchasedProducts()
        }
    }

    // MARK: - Load Products
    func loadProducts() async {
        isLoading = true
        errorMessage = nil
        do {
            let storeProducts = try await Product.products(for: StoreKitProductID.allIDs)
            var subs: [Product] = []
            var nonCons: [Product] = []

            for product in storeProducts {
                switch product.type {
                case .autoRenewable, .nonRenewable: subs.append(product)
                case .nonConsumable:                nonCons.append(product)
                default: break
                }
            }
            subscriptions = subs.sorted { $0.price < $1.price }
            nonConsumables = nonCons
            allProducts = subscriptions + nonConsumables
            isLoading = false
        } catch {
            isLoading = false
            errorMessage = error.localizedDescription
            purchaseState = .failed(errorMessage ?? "Unknown error")
        }
    }

    // MARK: - Purchase
    func purchase(_ product: Product) async throws -> Transaction? {
        purchaseState = .purchasing
        errorMessage = nil
        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                let transaction = try checkVerified(verification)
                await updatePurchasedProducts()
                await transaction.finish()
                purchaseState = .purchased
                return transaction
            case .userCancelled:
                purchaseState = .cancelled
                throw StoreKitError.userCancelled
            case .pending:
                purchaseState = .pending
                throw StoreKitError.pending
            @unknown default:
                purchaseState = .failed("Unknown result")
                throw StoreKitError.unknown
            }
        } catch StoreKitError.userCancelled {
            purchaseState = .cancelled
            throw StoreKitError.userCancelled
        } catch StoreKitError.pending {
            purchaseState = .pending
            throw StoreKitError.pending
        } catch {
            let msg = error.localizedDescription
            purchaseState = .failed(msg)
            errorMessage = msg
            throw StoreKitError.purchaseFailed(error)
        }
    }

    // MARK: - Restore
    func restorePurchases() async {
        purchaseState = .loading
        do {
            try await AppStore.sync()
            await updatePurchasedProducts()
            purchaseState = isPremium ? .purchased : .idle
        } catch {
            errorMessage = error.localizedDescription
            purchaseState = .failed(errorMessage ?? "Unknown error")
        }
    }

    // MARK: - Verification
    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:       throw StoreKitError.verificationFailed
        case .verified(let v):  return v
        }
    }

    // MARK: - Update Purchased
    func updatePurchasedProducts() async {
        var subs: Set<String> = []
        var nonCons: Set<String> = []
        for await result in Transaction.currentEntitlements {
            guard let transaction = try? checkVerified(result) else { continue }
            guard transaction.revocationDate == nil else { continue }
            switch transaction.productType {
            case .autoRenewable, .nonRenewable: subs.insert(transaction.productID)
            case .nonConsumable:                nonCons.insert(transaction.productID)
            default: break
            }
        }
        purchasedSubscriptions = subs
        purchasedNonConsumables = nonCons
    }

    // MARK: - Transaction Listener
    private func listenForTransactions() -> Task<Void, Error> {
        Task.detached { [weak self] in
            for await result in Transaction.updates {
                guard let self else { continue }
                if case .verified(let tx) = result {
                    await self.updatePurchasedProducts()
                    await tx.finish()
                }
            }
        }
    }

    // MARK: - Helpers
    func product(for id: StoreKitProductID) -> Product? {
        allProducts.first { $0.id == id.rawValue }
    }

    func formattedPrice(for product: Product) -> String { product.displayPrice }

    func resetState() {
        purchaseState = .idle
        errorMessage = nil
    }
}

// MARK: - Product Extensions
extension Product {
    var periodLabel: String {
        guard let sub = subscription else { return "One-time" }
        let unit = sub.subscriptionPeriod.unit
        let value = sub.subscriptionPeriod.value
        switch unit {
        case .day:   return value == 7 ? "per week" : "per \(value) days"
        case .week:  return "per week"
        case .month: return value == 1 ? "per month" : "per \(value) months"
        case .year:  return "per year"
        @unknown default: return ""
        }
    }

    var savingsLabel: String? {
        guard let sub = subscription else { return nil }
        switch sub.subscriptionPeriod.unit {
        case .year: return "Best Value — Save 60%"
        default:    return nil
        }
    }

    var isPopular: Bool {
        subscription?.subscriptionPeriod.unit == .year
    }
}
