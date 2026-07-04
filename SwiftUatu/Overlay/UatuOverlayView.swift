//
//  UatuOverlayView.swift
//  SwiftUatu
//
//  Created by Meet Brahmbhatt on 10/06/26.
//

import SwiftUI

// UatuOverlayView is a floating HUD that displays live render counts for tracked views.
// It sits on top of your app's content and refreshes every 0.5 seconds by polling MetricsStore.
//
// It is never used directly — attach it via .uatuOverlay(uatu:) on any root view.
struct UatuOverlayView: View {

    let metricsStore: MetricsStore

    // Local snapshot of MetricsStore data, refreshed on a timer.
    // Using @State here keeps the overlay self-contained — no need to make MetricsStore observable.
    @State private var renderCounts: [String: Int] = [:]

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Uatu 👁")
                .font(.system(size: 11, weight: .bold, design: .monospaced))
                .foregroundColor(.yellow)

            if renderCounts.isEmpty {
                Text("No views tracked yet")
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundColor(.gray)
            } else {
                // Sort alphabetically for a stable, readable display.
                ForEach(renderCounts.sorted(by: { $0.key < $1.key }), id: \.key) { name, count in
                    HStack(spacing: 6) {
                        Text(name)
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundColor(.white)
                        Spacer()
                        Text("\(count)×")
                            .font(.system(size: 10, weight: .semibold, design: .monospaced))
                            // Highlight views with high render counts as a quick visual cue.
                            .foregroundColor(count > 10 ? .orange : .green)
                    }
                }
            }
        }
        .padding(8)
        .background(Color.black.opacity(0.75))
        .cornerRadius(8)
        .frame(minWidth: 180)
        .padding(12)
        // Poll MetricsStore every 0.5s. The Task is cancelled automatically when the overlay leaves the hierarchy.
        .task {
            while !Task.isCancelled {
                renderCounts = await metricsStore.allRenderCounts()
                try? await Task.sleep(nanoseconds: 500_000_000) // 0.5s
            }
        }
    }
}

// MARK: - View Extension

public extension View {

    // Attaches the Uatu overlay to any view.
    // Respects config.showOverlay — when false, this is a no-op.
    //
    // Usage:
    //   ContentView()
    //       .uatuOverlay(uatu: uatu)
    func uatuOverlay(uatu: Uatu) -> some View {
        overlay(alignment: .topLeading) {
            if uatu.config.showOverlay {
                UatuOverlayView(metricsStore: uatu.metricsStore)
            }
        }
    }
}
