import SwiftUI

struct FilterSheetView: View {
    @Binding var selectedTypes: Set<String>
    @Binding var selectedGeneration: Int?
    @Binding var showMissingOnly: Bool
    @Binding var filterMegas: Bool
    @Binding var filterFemales: Bool
    @Binding var filterGigantamax: Bool
    @Binding var filterOtherForms: Bool
    @AppStorage("showMegas") private var showMegas = false
    @AppStorage("showFemales") private var showFemales = false
    @AppStorage("showGigantamax") private var showGigantamax = false
    @AppStorage("showOtherForms") private var showOtherForms = false
    @Environment(\.dismiss) private var dismiss
    @Environment(StoreManager.self) private var storeManager
    @State private var showUpgrade = false

    private var isPremium: Bool { storeManager.isPurchased }

    init(selectedTypes: Binding<Set<String>>, selectedGeneration: Binding<Int?>, showMissingOnly: Binding<Bool>,
         filterMegas: Binding<Bool>, filterFemales: Binding<Bool>, filterGigantamax: Binding<Bool>, filterOtherForms: Binding<Bool>) {
        self._selectedTypes = selectedTypes
        self._selectedGeneration = selectedGeneration
        self._showMissingOnly = showMissingOnly
        self._filterMegas = filterMegas
        self._filterFemales = filterFemales
        self._filterGigantamax = filterGigantamax
        self._filterOtherForms = filterOtherForms
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
                    if isPremium {
                        Picker("Generation", selection: $selectedGeneration) {
                            Text("All").tag(Int?.none)
                            ForEach(1...9, id: \.self) { gen in
                                Text("\(gen)").tag(Int?.some(gen))
                            }
                        }
                        .pickerStyle(.segmented)
                        .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                    } else {
                        Button {
                            showUpgrade = true
                        } label: {
                            HStack {
                                Text("Generation")
                                    .foregroundStyle(.secondary)
                                Spacer()
                                Image(systemName: "lock.fill")
                                    .font(.caption)
                                    .foregroundStyle(.orange)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }

                if showMegas || showGigantamax || showFemales || showOtherForms {
                    Section("Forms") {
                        if showMegas { Toggle("Mega", isOn: $filterMegas) }
                        if showGigantamax { Toggle("Gigantamax", isOn: $filterGigantamax) }
                        if showFemales { Toggle("Female", isOn: $filterFemales) }
                        if showOtherForms { Toggle("Other Forms", isOn: $filterOtherForms) }
                    }
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
                            filterMegas = true
                            filterFemales = true
                            filterGigantamax = true
                            filterOtherForms = true
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
        .sheet(isPresented: $showUpgrade) {
            PremiumUpgradeView()
        }
    }

    private var hasActiveFilters: Bool {
        !selectedTypes.isEmpty || selectedGeneration != nil || showMissingOnly
        || (showMegas && !filterMegas) || (showFemales && !filterFemales)
        || (showGigantamax && !filterGigantamax) || (showOtherForms && !filterOtherForms)
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
