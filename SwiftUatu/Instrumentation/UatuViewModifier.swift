//
//  UatuViewModifier.swift
//  SwiftUatu
//
//  Created by Meet Brahmbhatt on 10/06/26.
//

import SwiftUI

/**
    UatuViewModifier is the instrumentation layer's entry point into a SwiftUI view.
    It is the only place in the framework that touches SwiftUI directly.

    What it does
    It hooks into two lifecycle points:
      - onAppear    → emits .viewAppeared    (fires when the view enters the view hierarchy)
      - onDisappear → emits .viewDisappeared (fires when the view leaves the view hierarchy)

    Why not render counting here?
    A ViewModifier's body(content:) is only re-called when the modifier's own inputs change,
    not when the wrapped view's internal state changes. SwiftUI skips re-evaluating modifiers
    with stable inputs as an optimization. Render counting must therefore happen inline,
    inside the view's own body, via uatu.trackRender("ViewName").

    EventBus access:
    Publishing an event is `async`, so we dispatch it with `Task { }` — fire and forget.
    We never await inside a synchronous SwiftUI context.

    Usage:
    Consumers never use this modifier directly. They call `.trackWithUatu(...)` on any View,
    which is defined as a View extension below.
 */
struct UatuViewModifier: ViewModifier {

    let viewName: String
    let eventBus: EventBus

    func body(content: Content) -> some View {
        content
            .onAppear {
                emitEvent(.viewAppeared(viewName: viewName))
            }
            .onDisappear {
                emitEvent(.viewDisappeared(viewName: viewName))
            }
    }

    // MARK: - Private

    private func emitEvent(_ type: ProfilerEventType) {
        let event = ProfilerEvent(
            type: type,
            source: ProfilerEventSource(viewName: viewName)
        )
        // EventBus.publish is async. We can't await here (body is synchronous),
        // so we fire a detached Task. The event is a value type — fully Sendable — so
        // capturing it in the Task closure is safe.
        Task {
            await eventBus.publish(event)
        }
    }
}

// MARK: - View Extension
public extension View {
    /**
        Attaches SwiftUatu instrumentation to this view.
        Example:
        ```
        FeedView()
            .trackWithUatu(name: "FeedView", eventBus: uatu.eventBus)
        ```
     */
    func trackWithUatu(name: String, eventBus: EventBus) -> some View {
        modifier(UatuViewModifier(viewName: name, eventBus: eventBus))
    }
}
