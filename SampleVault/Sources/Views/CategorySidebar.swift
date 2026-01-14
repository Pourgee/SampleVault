//
//  CategorySidebar.swift
//  SampleVault
//
//  Sidebar for category navigation
//

import SwiftUI

struct CategorySidebar: View {
    @EnvironmentObject var viewModel: AppViewModel

    var body: some View {
        List(selection: Binding(
            get: { viewModel.selectedCategory },
            set: { viewModel.selectCategory($0) }
        )) {
            Section("Library") {
                NavigationLink(value: nil as CategoryType?) {
                    Label {
                        HStack {
                            Text("All Samples")
                            Spacer()
                            Text("\(viewModel.totalSampleCount)")
                                .foregroundStyle(.secondary)
                                .font(.caption)
                        }
                    } icon: {
                        Image(systemName: "music.note.list")
                    }
                }

                NavigationLink(value: nil as CategoryType?) {
                    Label {
                        HStack {
                            Text("Favorites")
                            Spacer()
                            Text("\(viewModel.favoritesCount)")
                                .foregroundStyle(.secondary)
                                .font(.caption)
                        }
                    } icon: {
                        Image(systemName: "star.fill")
                            .foregroundStyle(.yellow)
                    }
                }
                .simultaneousGesture(TapGesture().onEnded {
                    viewModel.filterFavoritesOnly.toggle()
                })
            }

            Section("Categories") {
                ForEach(CategoryType.allCases.filter { $0 != .uncategorized }, id: \.self) { category in
                    CategoryRow(category: category)
                }
            }

            Section("Other") {
                NavigationLink(value: CategoryType.uncategorized) {
                    Label {
                        HStack {
                            Text("Uncategorized")
                            Spacer()
                            Text("\(viewModel.categoryCount(.uncategorized))")
                                .foregroundStyle(.secondary)
                                .font(.caption)
                        }
                    } icon: {
                        Image(systemName: "questionmark.folder")
                    }
                }
            }
        }
        .listStyle(.sidebar)
        .navigationTitle("Library")
    }
}

struct CategoryRow: View {
    @EnvironmentObject var viewModel: AppViewModel
    let category: CategoryType

    @State private var isExpanded = false

    var body: some View {
        if category.subcategories.isEmpty {
            NavigationLink(value: category) {
                Label {
                    HStack {
                        Text(category.rawValue)
                        Spacer()
                        Text("\(viewModel.categoryCount(category))")
                            .foregroundStyle(.secondary)
                            .font(.caption)
                    }
                } icon: {
                    Text(category.icon)
                }
            }
        } else {
            DisclosureGroup(
                isExpanded: $isExpanded,
                content: {
                    ForEach(category.subcategories, id: \.self) { subcategory in
                        NavigationLink(value: category) {
                            HStack {
                                Text(subcategory)
                                    .font(.callout)
                                Spacer()
                                // Count for subcategory would require additional filtering
                            }
                        }
                        .padding(.leading, 8)
                    }
                },
                label: {
                    HStack {
                        Text(category.icon)
                        Text(category.rawValue)
                        Spacer()
                        Text("\(viewModel.categoryCount(category))")
                            .foregroundStyle(.secondary)
                            .font(.caption)
                    }
                }
            )
        }
    }
}

#Preview {
    NavigationSplitView {
        CategorySidebar()
            .environmentObject(AppViewModel())
    } detail: {
        Text("Select a category")
    }
    .frame(width: 800, height: 600)
}
