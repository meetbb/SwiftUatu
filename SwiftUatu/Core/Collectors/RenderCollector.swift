//
//  RenderCollector.swift
//  SwiftUatu
//
//  Created by Meet Brahmbhatt on 10/06/26.
//

import Foundation

/**
    RenderCollector is the first concrete metric collector in SwiftUatu.
    It listens to the EventBus, picks out view render signals, and writes
    the results into the MetricsStore.

    One collector, one concern: render counts. When a `.viewRendered` event
    arrives, increment the count for that view. Nothing else.

    Why an actor?
    RenderCollector holds a reference to the MetricsStore and will be called
    from EventBus subscriber closures, which run in async contexts. Making it
    an actor keeps those calls safe without any manual synchronization.

    Lifecycle
    Call `start()` once after initialization. It registers a single subscriber
    closure with the EventBus. From that point on, the collector is passive —
    it reacts to events as they arrive; it never polls.

    Extensibility note
    Future collectors (FPSCollector, MemoryCollector, etc.) follow the same
    pattern: actor, `start()` method, one subscription, one concern.
 */
public actor RenderCollector {

    private let eventBus: EventBus
    private let metricsStore: MetricsStore

    public init(eventBus: EventBus, metricsStore: MetricsStore) {
        self.eventBus = eventBus
        self.metricsStore = metricsStore
    }

    // Registers this collector with the EventBus.
    // Call once during framework initialization.
    public func start() async {
        /*
         Here, [weak self] is very important. Because EventBus owns the closure,
         and RenderCollector owns EventBus – without weak, that's a retain cycle.
        */
        await eventBus.subscribe { [weak self] event in
            await self?.handle(event)
            // Important: Here handle function is an actor-isolated async method,
            // so await is correct.
        }
    }

    // MARK: - Private
    private func handle(_ event: ProfilerEvent) async {
        switch event.type {
        case .viewRendered(let viewName):
            await metricsStore.incrementRenderCount(for: viewName)
            // For example, if a View X is rendered 12 times,
            // metricsStore increments its render count 12 times.
        case .viewAppeared, .viewDisappeared:
            // Not handled by this collector.
            // Future lifecycle collectors will pick these up.
            break
        }
    }
}
