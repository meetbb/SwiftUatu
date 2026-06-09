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
    
    private var renderCounts: [String: Int] = [:]
    
    public init() {}
    
    // This func is called by the RenderCollector each time a viewRendered event arrives.
    public func incrementRenderCount(for viewName: String) {
        renderCounts[viewName, default: 0] += 1
    }
    
    // This function is called by the overlay or analysis engine to read the current count for a specific view.
    public func renderCount(for viewName: String) -> Int {
        renderCounts[viewName, default: 0]
    }
    
    // This function returns the full snapshot. Useful for the overlay to display all tracked views at once.
    public func allRenderCounts() -> [String: Int] {
        renderCounts
    }
}
