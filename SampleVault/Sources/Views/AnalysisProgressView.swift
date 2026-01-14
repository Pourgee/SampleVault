//
//  AnalysisProgressView.swift
//  SampleVault
//
//  View showing audio analysis progress
//

import SwiftUI

struct AnalysisProgressView: View {
    @EnvironmentObject var viewModel: AppViewModel

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "waveform.circle.fill")
                    .font(.title2)
                    .foregroundStyle(.blue)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Analyzing Audio")
                        .font(.headline)

                    if let progress = viewModel.analysisProgress {
                        Text("\(progress.current) of \(progress.total) samples")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        if let sample = progress.currentSample {
                            Text(sample.filename)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                        }
                    }
                }

                Spacer()

                if let progress = viewModel.analysisProgress {
                    Text("\(Int(progress.percentage))%")
                        .font(.headline)
                        .monospacedDigit()
                        .foregroundStyle(.secondary)
                }

                Button(action: {
                    viewModel.cancelAnalysis()
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }

            if let progress = viewModel.analysisProgress {
                ProgressView(value: Double(progress.current), total: Double(progress.total))
                    .progressViewStyle(.linear)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(8)
    }
}

#Preview {
    AnalysisProgressView()
        .environmentObject(AppViewModel())
        .padding()
        .frame(width: 600)
}
