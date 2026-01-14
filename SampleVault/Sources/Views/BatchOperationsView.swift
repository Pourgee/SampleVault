//
//  BatchOperationsView.swift
//  SampleVault
//
//  Batch operations toolbar for selected samples
//

import SwiftUI

struct BatchOperationsView: View {
    @EnvironmentObject var viewModel: AppViewModel
    @State private var showingTagEditor = false
    @State private var showingCategoryPicker = false
    @State private var showingDeleteConfirmation = false

    var body: some View {
        HStack(spacing: 16) {
            // Selection info
            HStack(spacing: 8) {
                Text("\(viewModel.selectedSamples.count) selected")
                    .font(.body)
                    .fontWeight(.medium)

                Button("Select All") {
                    viewModel.selectAll()
                }
                .buttonStyle(.bordered)
                .controlSize(.small)

                if !viewModel.selectedSamples.isEmpty {
                    Button("Deselect All") {
                        viewModel.deselectAll()
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }
            }

            Divider()
                .frame(height: 24)

            // Batch operations
            HStack(spacing: 8) {
                Button(action: {
                    showingTagEditor = true
                }) {
                    Label("Tags", systemImage: "tag")
                }
                .buttonStyle(.bordered)
                .disabled(viewModel.selectedSamples.isEmpty)

                Button(action: {
                    showingCategoryPicker = true
                }) {
                    Label("Category", systemImage: "folder")
                }
                .buttonStyle(.bordered)
                .disabled(viewModel.selectedSamples.isEmpty)

                Button(action: {
                    Task {
                        await viewModel.batchToggleFavorite()
                    }
                }) {
                    Label("Favorite", systemImage: "star")
                }
                .buttonStyle(.bordered)
                .disabled(viewModel.selectedSamples.isEmpty)

                Button(action: {
                    showingDeleteConfirmation = true
                }) {
                    Label("Delete", systemImage: "trash")
                }
                .buttonStyle(.bordered)
                .tint(.red)
                .disabled(viewModel.selectedSamples.isEmpty)
            }

            Spacer()

            // Exit selection mode
            Button("Done") {
                viewModel.toggleSelectionMode()
            }
            .buttonStyle(.borderedProminent)
        }
        .padding(.horizontal)
        .padding(.vertical, 12)
        .background(Color(nsColor: .controlBackgroundColor))
        .overlay(
            Rectangle()
                .fill(Color.accentColor.opacity(0.1))
                .frame(height: 2),
            alignment: .top
        )
        .sheet(isPresented: $showingTagEditor) {
            TagEditorView(samples: viewModel.selectedSampleObjects)
                .environmentObject(viewModel)
        }
        .sheet(isPresented: $showingCategoryPicker) {
            CategoryPickerView()
                .environmentObject(viewModel)
        }
        .alert("Delete Samples", isPresented: $showingDeleteConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                Task {
                    await viewModel.batchDelete()
                }
            }
        } message: {
            Text("Are you sure you want to delete \(viewModel.selectedSamples.count) sample(s)? This action cannot be undone.")
        }
    }
}

// MARK: - Category Picker
struct CategoryPickerView: View {
    @EnvironmentObject var viewModel: AppViewModel
    @Environment(\.dismiss) var dismiss

    @State private var selectedCategory: CategoryType?
    @State private var selectedSubcategory: String?

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Set Category")
                    .font(.headline)

                Spacer()

                Button("Apply") {
                    Task {
                        await viewModel.batchSetCategory(
                            selectedCategory,
                            subcategory: selectedSubcategory
                        )
                        dismiss()
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(selectedCategory == nil)
            }
            .padding()

            Divider()

            // Category list
            List {
                Section("Categories") {
                    ForEach(CategoryType.allCases, id: \.self) { category in
                        Button(action: {
                            if selectedCategory == category {
                                selectedCategory = nil
                                selectedSubcategory = nil
                            } else {
                                selectedCategory = category
                                selectedSubcategory = nil
                            }
                        }) {
                            HStack {
                                Text(category.icon)
                                    .font(.title3)

                                Text(category.rawValue)

                                Spacer()

                                if selectedCategory == category {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(.accentColor)
                                }
                            }
                        }
                        .buttonStyle(.plain)

                        // Subcategories
                        if let selected = selectedCategory,
                           selected == category,
                           !category.subcategories.isEmpty {
                            ForEach(category.subcategories, id: \.self) { subcategory in
                                Button(action: {
                                    selectedSubcategory = subcategory
                                }) {
                                    HStack {
                                        Text(subcategory)
                                            .padding(.leading, 32)

                                        Spacer()

                                        if selectedSubcategory == subcategory {
                                            Image(systemName: "checkmark")
                                                .foregroundStyle(.accentColor)
                                        }
                                    }
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }

                Section {
                    Button(action: {
                        selectedCategory = nil
                        selectedSubcategory = nil
                    }) {
                        HStack {
                            Text("Remove Category")
                                .foregroundStyle(.red)

                            Spacer()

                            if selectedCategory == nil {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(.accentColor)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .frame(width: 350, height: 500)
    }
}

// MARK: - Preview
#Preview("Batch Operations") {
    let viewModel = AppViewModel()
    viewModel.isSelectionMode = true
    viewModel.selectedSamples = [UUID(), UUID(), UUID()]

    return BatchOperationsView()
        .environmentObject(viewModel)
}

#Preview("Category Picker") {
    CategoryPickerView()
        .environmentObject(AppViewModel())
}
