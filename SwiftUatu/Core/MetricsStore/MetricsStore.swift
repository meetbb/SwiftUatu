//
//  MetricsStore.swift
//  SwiftUatu
//
//  Created by Meet Brahmbhatt on 09/06/26.
//

/*
    The MetricsStore is the single source of truth for all computed metrics in the framework.
    Collectors don't hold onto their own results – they process an event and immediately write
    the result into the store. The overlay and analysis engine then read from the store whenever
    they need current data.
*/

import Foundation

public actor MetricsStore {

    // MARK: - Render Counts (v0.1.0)

    private var renderCounts: [String: Int] = [:]

    public init() {}

    // Called by RenderCollector each time a .viewRendered event arrives.
    public func incrementRenderCount(for viewName: String) {
        renderCounts[viewName, default: 0] += 1
    }

    // Returns the render count for a single view.
    public func renderCount(for viewName: String) -> Int {
        renderCounts[viewName, default: 0]
    }

    // Returns the full render count snapshot. Used by the overlay.
    public func allRenderCounts() -> [String: Int] {
        renderCounts
    }

    // MARK: - FPS (v0.2.0)

    // Stores the most recent FPS sample written by FPSCollector.
    // 0.0 means no sample has been recorded yet.
    private var _currentFPS: Double = 0.0

    // Called by FPSCollector once per second with the measured frame rate.
    public func updateFPS(_ fps: Double) {
        _currentFPS = fps
    }

    // Read by the overlay to display the current FPS.
    public func currentFPS() -> Double {
        _currentFPS
    }
}
