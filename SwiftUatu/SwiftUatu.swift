//
//  SwiftUatu.swift
//  SwiftUatu
//
//  Created by Meet Brahmbhatt on 09/06/26.
//

import Combine

// Uatu is the framework's single entry point.
// It owns all core components and wires them together.
// Create one instance per app — typically at the root of your SwiftUI hierarchy.
//
// Usage:
//   let uatu = Uatu()
//   await uatu.start()
//
//   // Then in any view:
//   FeedView().trackWithUatu(name: "FeedView", eventBus: uatu.eventBus)
@MainActor
public final class Uatu: ObservableObject {

    // MARK: - Public interface

    public let config: UatuConfig

    // Exposed so views can pass it to .trackWithUatu(name:eventBus:)
    public let eventBus: EventBus

    // Exposed so the overlay and analysis engine can read collected metrics.
    public let metricsStore: MetricsStore

    // MARK: - Private

    private let renderCollector: RenderCollector
    private let fpsCollector: FPSCollector

    // MARK: - Init

    public init(config: UatuConfig = UatuConfig()) {
        self.config = config
        self.eventBus = EventBus()
        self.metricsStore = MetricsStore()
        self.renderCollector = RenderCollector(eventBus: eventBus, metricsStore: metricsStore)
        self.fpsCollector = FPSCollector(metricsStore: metricsStore)
    }

    // MARK: - Lifecycle

    // Starts all metric collectors. Call once after init, before any views appear.
    // When config.isEnabled is false, this is a no-op.
    public func start() async {
        guard config.isEnabled else { return }
        await renderCollector.start()
        fpsCollector.start()
    }

    // MARK: - Render Tracking

    // Call this inside a view's body to count that evaluation as a render.
    // SwiftUI calls body every time a view re-renders, so this fires on every re-render.
    //
    // Usage — add this as the first line inside any view's body:
    //   let _ = uatu.trackRender("MyView")
    //
    // Why `let _ =`?
    // SwiftUI requires body to be a pure computed property, but `let _ = expr` is a valid
    // way to evaluate an expression for its side effect while discarding the result.
    // Since trackRender() returns Void, this is idiomatic and compiler-safe.
    public func trackRender(_ name: String) {
        guard config.isEnabled else { return }
        let event = ProfilerEvent(
            type: .viewRendered(viewName: name),
            source: ProfilerEventSource(viewName: name)
        )
        Task {
            await eventBus.publish(event)
        }
    }
}
