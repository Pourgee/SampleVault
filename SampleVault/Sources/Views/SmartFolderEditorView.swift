//
//  SmartFolderEditorView.swift
//  SampleVault
//
//  Smart folder creation and editing UI
//

import SwiftUI

struct SmartFolderEditorView: View {
    @EnvironmentObject var viewModel: AppViewModel
    @Environment(\.dismiss) var dismiss

    @State private var folderName: String = ""
    @State private var selectedIcon: String = "folder.badge.gearshape"

    let icons = [
        "folder.badge.gearshape", "star.fill", "clock", "play.circle",
        "speedometer", "tortoise", "hare", "waveform",
        "music.note.list", "heart.fill", "bolt.fill", "flame.fill"
    ]

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Create Smart Folder")
                    .font(.headline)

                Spacer()

                Button("Create") {
                    createFolder()
                }
                .buttonStyle(.borderedProminent)
                .disabled(folderName.isEmpty)
            }
            .padding()

            Divider()

            // Content
            Form {
                Section("Folder Details") {
                    TextField("Name", text: $folderName)
                        .textFieldStyle(.roundedBorder)

                    Text("Icon")
                        .font(.subheadline)

                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 12) {
                        ForEach(icons, id: \.self) { icon in
                            Button(action: {
                                selectedIcon = icon
                            }) {
                                Image(systemName: icon)
                                    .font(.title2)
                                    .frame(width: 44, height: 44)
                                    .background(
                                        selectedIcon == icon ?
                                            Color.accentColor.opacity(0.2) :
                                            Color.gray.opacity(0.1)
                                    )
                                    .cornerRadius(8)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }

                Section("Current Filters") {
                    let filters = viewModel.getCurrentFilters()

                    if filters.isEmpty {
                        Text("No filters applied")
                            .foregroundStyle(.secondary)
                            .italic()
                    } else {
                        Text(filters.description)
                            .font(.body)
                    }
                }

                Section("How Smart Folders Work") {
                    Text("Smart Folders save your current search and filter settings. When you click a Smart Folder, it automatically applies those filters to show matching samples.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .formStyle(.grouped)
        }
        .frame(width: 500, height: 550)
    }

    private func createFolder() {
        Task {
            await viewModel.createSmartFolder(name: folderName, icon: selectedIcon)
            dismiss()
        }
    }
}

// MARK: - Preview
#Preview {
    SmartFolderEditorView()
        .environmentObject({
            let vm = AppViewModel()
            vm.searchQuery = "kick"
            vm.selectedCategory = .drums
            vm.filterBPMRange = 120...140
            return vm
        }())
}
