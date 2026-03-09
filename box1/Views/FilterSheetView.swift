import SwiftUI

struct FilterSheetView: View {
    @Binding var selectedTypes: Set<String>
    @Binding var selectedGeneration: Int?
    @Binding var showMissingOnly: Bool
    @Environment(\.dismiss) private var dismiss

    init(selectedTypes: Binding<Set<String>>, selectedGeneration: Binding<Int?>, showMissingOnly: Binding<Bool>) {
        self._selectedTypes = selectedTypes
        self._selectedGeneration = selectedGeneration
        self._showMissingOnly = showMissingOnly
        self._isTypeExpanded = State(initialValue: !selectedTypes.wrappedValue.isEmpty)
    }

    private static let typeData: [(name: String, color: String)] = [
        ("Normal", "#A8A77A"), ("Fire", "#EE8130"), ("Water", "#6390F0"),
        ("Electric", "#F7D02C"), ("Grass", "#7AC74C"), ("Ice", "#96D9D6"),
        ("Fighting", "#C22E28"), ("Poison", "#A33EA1"), ("Ground", "#E2BF65"),
        ("Flying", "#A98FF3"), ("Psychic", "#F95587"), ("Bug", "#A6B91A"),
        ("Rock", "#B6A136"), ("Ghost", "#735797"), ("Dragon", "#6F35FC"),
        ("Dark", "#705746"), ("Steel", "#B7B7CE"), ("Fairy", "#D685AD"),
    ]

    @State private var isTypeExpanded: Bool
    private let typeColumns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 3)

    var body: some View {
        NavigationStack {
            List {
                Section {
                    DisclosureGroup(isExpanded: $isTypeExpanded) {
                        LazyVGrid(columns: typeColumns, spacing: 8) {
                            ForEach(Self.typeData, id: \.name) { type in
                                typePill(name: type.name, hex: type.color)
                            }
                        }
                        .padding(.vertical, 4)
                    } label: {
                        HStack {
                            Text("Type")
                            if !selectedTypes.isEmpty {
                                Text(selectedTypes.sorted().joined(separator: ", "))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(1)
                            }
                        }
                    }
                    .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                }

                Section("Generation") {
                    Picker("Generation", selection: $selectedGeneration) {
                        Text("All").tag(Int?.none)
                        ForEach(1...9, id: \.self) { gen in
                            Text("\(gen)").tag(Int?.some(gen))
                        }
                    }
                    .pickerStyle(.segmented)
                    .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                }

                Section {
                    Toggle("Show Missing Only", isOn: $showMissingOnly)
                }

            }
            .navigationTitle("Filters")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    if hasActiveFilters {
                        Button("Clear", role: .destructive) {
                            selectedTypes.removeAll()
                            selectedGeneration = nil
                            showMissingOnly = false
                        }
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .fontWeight(.semibold)
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }

    private var hasActiveFilters: Bool {
        !selectedTypes.isEmpty || selectedGeneration != nil || showMissingOnly
    }

    private func typePill(name: String, hex: String) -> some View {
        let isSelected = selectedTypes.contains(name)
        let color = Color(hex: hex)

        return Button {
            if isSelected {
                selectedTypes.remove(name)
            } else {
                selectedTypes.insert(name)
            }
        } label: {
            Text(name)
                .font(.caption)
                .fontWeight(.semibold)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .foregroundStyle(isSelected ? .white : .primary)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(isSelected ? color : color.opacity(0.15))
                )
        }
        .buttonStyle(.plain)
    }
}
