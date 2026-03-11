import Foundation
import StoreKit
import Supabase

@MainActor @Observable
final class StoreManager {
    static let productId = "com.box1.premium"

    private(set) var isPurchased = false
    private(set) var product: Product?
    private var transactionListener: Task<Void, Never>?

    func start() async {
        transactionListener = listenForTransactions()
        await loadProduct()
        await checkPurchased()
    }

    // MARK: - Products

    func loadProduct() async {
        do {
            let products = try await Product.products(for: [Self.productId])
            product = products.first
        } catch {
            print("Error loading products: \(error)")
        }
    }

    // MARK: - Purchase

    func purchase() async throws {
        guard let product else { return }
        let result = try await product.purchase()
        switch result {
        case .success(let verification):
            let transaction = try checkVerified(verification)
            await transaction.finish()
            isPurchased = true
            await syncPremiumStatus(true)
        case .userCancelled, .pending:
            break
        @unknown default:
            break
        }
    }

    func restorePurchases() async {
        try? await AppStore.sync()
        await checkPurchased()
    }

    // MARK: - Entitlement Check

    func checkPurchased() async {
        var found = false
        for await result in Transaction.currentEntitlements {
            if let transaction = try? checkVerified(result),
               transaction.productID == Self.productId,
               transaction.revocationDate == nil {
                found = true
                await transaction.finish()
            }
        }
        isPurchased = found
    }

    // MARK: - Transaction Listener

    private func listenForTransactions() -> Task<Void, Never> {
        Task { [weak self] in
            for await result in Transaction.updates {
                guard let self else { return }
                if case .verified(let transaction) = result {
                    self.isPurchased = transaction.revocationDate == nil
                    await transaction.finish()
                    await self.syncPremiumStatus(self.isPurchased)
                }
            }
        }
    }

    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw StoreManagerError.failedVerification
        case .verified(let value):
            return value
        }
    }

    // MARK: - Supabase Sync

    private func syncPremiumStatus(_ isPremium: Bool) async {
        do {
            let userId = try await supabase.auth.session.user.id
            try await supabase
                .from("profiles")
                .update(["is_premium": isPremium])
                .eq("id", value: userId.uuidString)
                .execute()
        } catch {
            print("Error syncing premium status: \(error)")
        }
    }
}

enum StoreManagerError: LocalizedError {
    case failedVerification

    var errorDescription: String? {
        switch self {
        case .failedVerification: return "Transaction verification failed"
        }
    }
}
