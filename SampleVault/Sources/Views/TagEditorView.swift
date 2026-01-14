//
//  TagEditorView.swift
//  SampleVault
//
//  Tag editor for adding and managing tags on samples
//

import SwiftUI

struct TagEditorView: View {
    @EnvironmentObject var viewModel: AppViewModel
    @Environment(\.dismiss) var dismiss

    let samples: [Sample]

    @State private var availableTags: [Tag] = []
    @State private var selectedTags: Set<String> = []
    @State private var newTagName: String = ""
    @State private var showingNewTag: Bool = false
    @State private var newTagColor: Color = .blue

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Edit Tags")
                        .font(.headline)

                    if samples.count == 1 {
                        Text(samples[0].filename)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    } else {
                        Text("\(samples.count) samples selected")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()

                Button("Done") {
                    applyTags()
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()

            Divider()

            // Content
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // Current tags (for single sample)
                    if samples.count == 1, !samples[0].tags.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Current Tags")
                                .font(.subheadline)
                                .fontWeight(.medium)

                            FlowLayout(spacing: 8) {
                                ForEach(samples[0].tags, id: \.self) { tag in
                                    TagBubble(
                                        tag: tag,
                                        isSelected: true,
                                        onTap: {
                                            selectedTags.remove(tag)
                                        },
                                        onRemove: {
                                            selectedTags.remove(tag)
                                        }
                                    )
                                }
                            }
                        }

                        Divider()
                            .padding(.vertical, 8)
                    }

                    // Quick tag palette
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Quick Tags")
                                .font(.subheadline)
                                .fontWeight(.medium)

                            Spacer()

                            Button(action: {
                                showingNewTag = true
                            }) {
                                Label("New Tag", systemImage: "plus.circle")
                                    .font(.caption)
                            }
                        }

                        FlowLayout(spacing: 8) {
                            ForEach(availableTags, id: \.name) { tag in
                                TagBubble(
                                    tag: tag.name,
                                    isSelected: selectedTags.contains(tag.name),
                                    color: tag.color.flatMap { Color(hex: $0) },
                                    onTap: {
                                        toggleTag(tag.name)
                                    }
                                )
                            }
                        }
                    }

                    // New tag input
                    if showingNewTag {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Create New Tag")
                                .font(.subheadline)
                                .fontWeight(.medium)

                            HStack {
                                TextField("Tag name", text: $newTagName)
                                    .textFieldStyle(.roundedBorder)

                                ColorPicker("", selection: $newTagColor)
                                    .labelsHidden()
                                    .frame(width: 40)

                                Button("Add") {
                                    createNewTag()
                                }
                                .buttonStyle(.bordered)
                                .disabled(newTagName.isEmpty)

                                Button("Cancel") {
                                    showingNewTag = false
                                    newTagName = ""
                                }
                                .buttonStyle(.bordered)
                            }
                        }
                    }
                }
                .padding()
            }
        }
        .frame(width: 450, height: 400)
        .onAppear {
            loadTags()
            loadSelectedTags()
        }
    }

    private func loadTags() {
        Task {
            availableTags = try await DatabaseManager.shared.getAllTags()
        }
    }

    private func loadSelectedTags() {
        if samples.count == 1 {
            selectedTags = Set(samples[0].tags)
        } else {
            // For multiple samples, show tags that all samples have in common
            selectedTags = Set(samples[0].tags)
            for sample in samples.dropFirst() {
                selectedTags = selectedTags.intersection(sample.tags)
            }
        }
    }

    private func toggleTag(_ tagName: String) {
        if selectedTags.contains(tagName) {
            selectedTags.remove(tagName)
        } else {
            selectedTags.insert(tagName)
        }
    }

    private func createNewTag() {
        guard !newTagName.isEmpty else { return }

        let tag = Tag(
            name: newTagName.lowercased(),
            color: newTagColor.toHex(),
            isUserCreated: true
        )

        Task {
            do {
                try await DatabaseManager.shared.insertTag(tag)
                availableTags.append(tag)
                selectedTags.insert(tag.name)

                newTagName = ""
                showingNewTag = false
            } catch {
                print("Failed to create tag: \(error)")
            }
        }
    }

    private func applyTags() {
        Task {
            for sample in samples {
                var updatedSample = sample
                updatedSample.tags = Array(selectedTags)

                do {
                    try await DatabaseManager.shared.updateSample(updatedSample)

                    // Update in view model
                    if let index = await viewModel.samples.firstIndex(where: { $0.id == sample.id }) {
                        await MainActor.run {
                            viewModel.samples[index] = updatedSample
                        }
                    }
                } catch {
                    print("Failed to update sample tags: \(error)")
                }
            }

            // Refresh filtered samples
            await viewModel.applyFilters()
        }
    }
}

// MARK: - Tag Bubble Component
struct TagBubble: View {
    let tag: String
    let isSelected: Bool
    var color: Color? = nil
    var onTap: (() -> Void)? = nil
    var onRemove: (() -> Void)? = nil

    var body: some View {
        HStack(spacing: 4) {
            Text(tag)
                .font(.callout)

            if let onRemove = onRemove {
                Button(action: onRemove) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.caption)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            isSelected
                ? (color ?? .accentColor)
                : (color?.opacity(0.2) ?? Color.gray.opacity(0.2))
        )
        .foregroundStyle(isSelected ? .white : .primary)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(
                    isSelected ? Color.clear : Color.gray.opacity(0.3),
                    lineWidth: 1
                )
        )
        .contentShape(Rectangle())
        .onTapGesture {
            onTap?()
        }
    }
}

// MARK: - Flow Layout
struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(
            in: proposal.width ?? 0,
            subviews: subviews,
            spacing: spacing
        )
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(
            in: bounds.width,
            subviews: subviews,
            spacing: spacing
        )
        for (index, subview) in subviews.enumerated() {
            subview.place(at: result.positions[index], proposal: .unspecified)
        }
    }

    struct FlowResult {
        var size: CGSize = .zero
        var positions: [CGPoint] = []

        init(in maxWidth: CGFloat, subviews: Subviews, spacing: CGFloat) {
            var x: CGFloat = 0
            var y: CGFloat = 0
            var lineHeight: CGFloat = 0

            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)

                if x + size.width > maxWidth && x > 0 {
                    x = 0
                    y += lineHeight + spacing
                    lineHeight = 0
                }

                positions.append(CGPoint(x: x, y: y))
                lineHeight = max(lineHeight, size.height)
                x += size.width + spacing
            }

            self.size = CGSize(width: maxWidth, height: y + lineHeight)
        }
    }
}

// MARK: - Color Extensions
extension Color {
    init?(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            return nil
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }

    func toHex() -> String {
        #if canImport(AppKit)
        guard let components = NSColor(self).cgColor.components else { return "000000" }
        #else
        guard let components = UIColor(self).cgColor.components else { return "000000" }
        #endif

        let r = Float(components[0])
        let g = Float(components[1])
        let b = Float(components[2])

        return String(format: "%02lX%02lX%02lX",
                      lroundf(r * 255),
                      lroundf(g * 255),
                      lroundf(b * 255))
    }
}

// MARK: - Preview
#Preview {
    let sample = Sample(
        filename: "kick_808_hard.wav",
        path: "/test/kick_808_hard.wav",
        bookmarkData: Data(),
        tags: ["punchy", "808", "dark"]
    )

    return TagEditorView(samples: [sample])
        .environmentObject(AppViewModel())
}
