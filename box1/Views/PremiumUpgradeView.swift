import SwiftUI
import StoreKit

struct PremiumUpgradeView: View {
    @Environment(StoreManager.self) private var storeManager
    @Environment(\.dismiss) private var dismiss
    @State private var isPressing = false
    @State private var isPurchasing = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    VStack(alignment: .leading, spacing: 12) {
                        FeatureRow(icon: "sparkles", text: "Shiny tracking")
                        FeatureRow(icon: "globe.americas.fill", text: "Origin game tracking")
                        FeatureRow(icon: "square.stack.fill", text: "Forms (Mega, Gmax, Female)")
                        FeatureRow(icon: "gamecontroller.fill", text: "All game Pokedexes")
                        FeatureRow(icon: "line.3.horizontal.decrease", text: "Generation filter")
                        FeatureRow(icon: "character.cursor.ibeam", text: "Nicknames & notes")
                        FeatureRow(icon: "chart.bar.fill", text: "Full stats dashboard")
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .glassEffect(.regular, in: .rect(cornerRadius: 16))

                    purchaseButton

                    Button {
                        Task { await storeManager.restorePurchases() }
                    } label: {
                        Text("Restore Purchases")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                }
                .padding()
            }
            .navigationTitle("box1 Premium")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }

    private var purchaseButton: some View {
        Button {
            isPurchasing = true
            Task {
                try? await storeManager.purchase()
                isPurchasing = false
                if storeManager.isPurchased { dismiss() }
            }
        } label: {
            HStack(spacing: 8) {
                if isPurchasing {
                    ProgressView()
                        .tint(.white)
                } else {
                    Text("Unlock Premium")
                        .fontWeight(.semibold)
                    if let product = storeManager.product {
                        Text("·")
                        Text(product.displayPrice)
                            .fontWeight(.semibold)
                    }
                }
            }
            .font(.title3)
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(.blue, in: RoundedRectangle(cornerRadius: 16))
        }
        .disabled(isPurchasing)
        .scaleEffect(isPressing ? 0.95 : 1.0)
        .animation(.easeInOut(duration: 0.1), value: isPressing)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressing = true }
                .onEnded { _ in isPressing = false }
        )
    }
}

private struct FeatureRow: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(.green)
            Image(systemName: icon)
                .foregroundStyle(.tint)
                .frame(width: 24)
            Text(text)
                .font(.subheadline)
        }
    }
}
