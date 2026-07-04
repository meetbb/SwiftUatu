//
//  UatuConfig.swift
//  SwiftUatu
//
//  Created by Meet Brahmbhatt on 10/06/26.
//

import Foundation

// UatuConfig is a value type passed to Uatu at initialization.
// All properties have sensible defaults — callers only override what they need.
//
// Example:
//   let config = UatuConfig(isEnabled: false)   // disable in production
//   let uatu = Uatu(config: config)
public struct UatuConfig {

    // Master switch. When false, the EventBus receives no events
    // and no metrics are collected. Use this to disable Uatu in
    // production or release builds.
    //
    // Recommended pattern:
    //   isEnabled: ProcessInfo.processInfo.environment["UATU_ENABLED"] != nil
    public var isEnabled: Bool

    // Controls whether the debug overlay is shown on screen.
    // Independent of isEnabled — you can collect metrics without showing the overlay.
    public var showOverlay: Bool

    // The maximum number of render events stored per view name in MetricsStore.
    // Acts as a safety cap to prevent unbounded memory growth during long sessions.
    // Set to nil for no limit (not recommended in production).
    public var maxRenderCountPerView: Int?

    public init(
        isEnabled: Bool = true,
        showOverlay: Bool = true,
        maxRenderCountPerView: Int? = 1000
    ) {
        self.isEnabled = isEnabled
        self.showOverlay = showOverlay
        self.maxRenderCountPerView = maxRenderCountPerView
    }
}
