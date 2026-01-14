//
//  WaveformView.swift
//  SampleVault
//
//  Waveform visualization using Core Graphics
//

import SwiftUI

struct WaveformView: View {
    let waveformData: Data?
    let currentTime: TimeInterval
    let duration: TimeInterval
    let height: CGFloat
    var onSeek: ((TimeInterval) -> Void)?

    @State private var peaks: [Float] = []
    @State private var isHovering = false
    @State private var hoverPosition: CGFloat = 0

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Background
                Rectangle()
                    .fill(Color.gray.opacity(0.1))

                // Waveform
                if !peaks.isEmpty {
                    WaveformShape(peaks: peaks)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.accentColor.opacity(0.8),
                                    Color.accentColor.opacity(0.4)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .overlay(
                            WaveformShape(peaks: peaks)
                                .stroke(Color.accentColor, lineWidth: 0.5)
                        )

                    // Played portion overlay
                    if duration > 0 {
                        let playedWidth = geometry.size.width * (currentTime / duration)

                        WaveformShape(peaks: peaks)
                            .fill(Color.accentColor)
                            .frame(width: playedWidth)
                            .mask(
                                Rectangle()
                                    .frame(width: playedWidth)
                            )
                    }
                } else {
                    // Placeholder when no waveform data
                    Text("No waveform data")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }

                // Playhead indicator
                if duration > 0 && currentTime > 0 {
                    let playheadX = geometry.size.width * (currentTime / duration)

                    Rectangle()
                        .fill(Color.white.opacity(0.8))
                        .frame(width: 2)
                        .offset(x: playheadX)
                }

                // Hover indicator
                if isHovering && !peaks.isEmpty {
                    Rectangle()
                        .fill(Color.white.opacity(0.3))
                        .frame(width: 2)
                        .offset(x: hoverPosition)
                }
            }
            .frame(height: height)
            .cornerRadius(4)
            .contentShape(Rectangle())
            .onHover { hovering in
                isHovering = hovering
            }
            .onContinuousHover { phase in
                switch phase {
                case .active(let location):
                    hoverPosition = location.x
                case .ended:
                    isHovering = false
                }
            }
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        handleSeek(at: value.location.x, in: geometry.size.width)
                    }
            )
        }
        .frame(height: height)
        .onAppear {
            loadWaveformData()
        }
        .onChange(of: waveformData) { _, _ in
            loadWaveformData()
        }
    }

    private func loadWaveformData() {
        guard let waveformData = waveformData else {
            peaks = []
            return
        }

        Task {
            do {
                let data = try WaveformGenerator.WaveformData.decode(from: waveformData)
                await MainActor.run {
                    peaks = data.peaks
                }
            } catch {
                print("Failed to decode waveform data: \(error)")
                peaks = []
            }
        }
    }

    private func handleSeek(at x: CGFloat, in width: CGFloat) {
        guard duration > 0, let onSeek = onSeek else { return }

        let normalized = max(0, min(1, x / width))
        let seekTime = normalized * duration
        onSeek(seekTime)
    }
}

// MARK: - Waveform Shape
struct WaveformShape: Shape {
    let peaks: [Float]

    func path(in rect: CGRect) -> Path {
        var path = Path()

        guard !peaks.isEmpty else { return path }

        let width = rect.width
        let height = rect.height
        let centerY = height / 2
        let barWidth = width / CGFloat(peaks.count)

        for (index, peak) in peaks.enumerated() {
            let x = CGFloat(index) * barWidth
            let barHeight = CGFloat(peak) * centerY

            // Draw from center outward (symmetrical)
            let topY = centerY - barHeight
            let bottomY = centerY + barHeight

            path.move(to: CGPoint(x: x, y: centerY))
            path.addLine(to: CGPoint(x: x, y: topY))
            path.move(to: CGPoint(x: x, y: centerY))
            path.addLine(to: CGPoint(x: x, y: bottomY))
        }

        return path
    }
}

// MARK: - Compact Waveform (for list view)
struct CompactWaveformView: View {
    let waveformData: Data?
    let isPlaying: Bool

    @State private var peaks: [Float] = []

    var body: some View {
        GeometryReader { geometry in
            if !peaks.isEmpty {
                WaveformBarsShape(peaks: peaks)
                    .fill(isPlaying ? Color.accentColor : Color.gray.opacity(0.6))
            } else {
                Rectangle()
                    .fill(Color.gray.opacity(0.2))
            }
        }
        .frame(height: 24)
        .onAppear {
            loadWaveformData()
        }
        .onChange(of: waveformData) { _, _ in
            loadWaveformData()
        }
    }

    private func loadWaveformData() {
        guard let waveformData = waveformData else {
            peaks = []
            return
        }

        Task {
            do {
                let data = try WaveformGenerator.WaveformData.decode(from: waveformData)
                await MainActor.run {
                    // Downsample for compact view
                    let targetCount = min(50, data.peaks.count)
                    let stride = max(1, data.peaks.count / targetCount)
                    peaks = stride(from: 0, to: data.peaks.count, by: stride).map { data.peaks[$0] }
                }
            } catch {
                peaks = []
            }
        }
    }
}

// MARK: - Waveform Bars Shape (for compact view)
struct WaveformBarsShape: Shape {
    let peaks: [Float]

    func path(in rect: CGRect) -> Path {
        var path = Path()

        guard !peaks.isEmpty else { return path }

        let width = rect.width
        let height = rect.height
        let centerY = height / 2
        let barWidth = (width / CGFloat(peaks.count)) * 0.8  // 80% width for spacing
        let spacing = (width / CGFloat(peaks.count)) * 0.2

        for (index, peak) in peaks.enumerated() {
            let x = CGFloat(index) * (barWidth + spacing)
            let barHeight = max(2, CGFloat(peak) * height * 0.9)  // Min height of 2pt

            let rect = CGRect(
                x: x,
                y: centerY - barHeight / 2,
                width: barWidth,
                height: barHeight
            )

            path.addRoundedRect(in: rect, cornerSize: CGSize(width: 1, height: 1))
        }

        return path
    }
}

// MARK: - Preview
#Preview("Full Waveform") {
    let samplePeaks = (0..<100).map { i in
        Float(sin(Double(i) * 0.1) * 0.5 + 0.5)
    }

    let waveformData = try? WaveformGenerator.WaveformData(
        peaks: samplePeaks,
        sampleCount: 100,
        duration: 42
    ).encode()

    return VStack(spacing: 20) {
        WaveformView(
            waveformData: waveformData,
            currentTime: 15,
            duration: 42,
            height: 80
        ) { time in
            print("Seek to: \(time)")
        }

        WaveformView(
            waveformData: waveformData,
            currentTime: 0,
            duration: 42,
            height: 120
        )
    }
    .padding()
    .frame(width: 600)
}

#Preview("Compact Waveform") {
    let samplePeaks = (0..<100).map { i in
        Float(sin(Double(i) * 0.1) * 0.5 + 0.5)
    }

    let waveformData = try? WaveformGenerator.WaveformData(
        peaks: samplePeaks,
        sampleCount: 100,
        duration: 42
    ).encode()

    return VStack(spacing: 12) {
        CompactWaveformView(waveformData: waveformData, isPlaying: false)
        CompactWaveformView(waveformData: waveformData, isPlaying: true)
        CompactWaveformView(waveformData: nil, isPlaying: false)
    }
    .padding()
    .frame(width: 400)
}
