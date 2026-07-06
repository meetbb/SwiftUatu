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

    @State private var fps: Double = 0.0
    @State private var renderCounts: [String: Int] = [:]

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {

            // Header
            Text("Uatu 👁")
                .font(.system(size: 11, weight: .bold, design: .monospaced))
                .foregroundColor(.yellow)

            Divider().background(Color.gray.opacity(0.5))

            // Runtime metrics section (v0.2.0)
            HStack(spacing: 6) {
                Text("FPS")
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundColor(.white)
                Spacer()
                Text(fps == 0 ? "—" : String(format: "%.0f", fps))
                    .font(.system(size: 10, weight: .semibold, design: .monospaced))
                    // Below 50 FPS is a warning sign; below 30 is a serious problem.
                    .foregroundColor(fpsColor(fps))
            }

            Divider().background(Color.gray.opacity(0.5))

            // Render counts section (v0.1.0)
            if renderCounts.isEmpty {
                Text("No views tracked yet")
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundColor(.gray)
            } else {
                ForEach(renderCounts.sorted(by: { $0.key < $1.key }), id: \.key) { name, count in
                    HStack(spacing: 6) {
                        Text(name)
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundColor(.white)
                        Spacer()
                        Text("\(count)×")
                            .font(.system(size: 10, weight: .semibold, design: .monospaced))
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
        .task {
            while !Task.isCancelled {
                fps = await metricsStore.currentFPS()
                renderCounts = await metricsStore.allRenderCounts()
                try? await Task.sleep(nanoseconds: 500_000_000) // 0.5s
            }
        }
    }

    // MARK: - Private

    private func fpsColor(_ fps: Double) -> Color {
        if fps == 0    { return .gray }
        if fps >= 50   { return .green }
        if fps >= 30   { return .orange }
        return .red
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
