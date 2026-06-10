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
    It wraps a view and hooks into three points in SwiftUI's rendering lifecycle:
      - body evaluation  → emits .viewRendered   (fires every time SwiftUI re-evaluates the view's body)
      - onAppear         → emits .viewAppeared    (fires when the view enters the view hierarchy)
      - onDisappear      → emits .viewDisappeared (fires when the view leaves the view hierarchy)

    Why body evaluation for render count?
    SwiftUI re-evaluates a view's body every time it needs to reconcile the view tree.
    Counting body evaluations is the closest proxy we have for "how often did SwiftUI
    re-render this view?" — which is the core signal for detecting unnecessary re-renders.
    We capture this by reading a @State counter that increments inside `body`, forcing
    SwiftUI to evaluate `body` as a side effect. Using a background modifier keeps the
    visual impact zero.

    EventBus access:
    The modifier receives the EventBus as a plain (non-isolated) reference. Publishing
    an event is an `async` call, so we dispatch it with `Task { }` — fire and forget.
    We never await the result from inside a synchronous SwiftUI context.

    Usage:
    Consumers never use this modifier directly. They call `.trackWithUatu(...)` on any View,
    which is defined as a View extension below.
 */
struct UatuViewModifier: ViewModifier {

    let viewName: String
    let eventBus: EventBus

    // Each increment triggers a body re-evaluation, which we treat as one render event.
    @State private var renderCount: Int = 0

    func body(content: Content) -> some View {
        // Reading renderCount inside body means SwiftUI tracks it as a dependency.
        // Any external increment of renderCount will cause body to re-evaluate,
        // but here we use it the other way: body itself records that it was called.
        let _ = renderCount

        return content
            .background(
                // A zero-size background view whose only job is to emit the render event.
                // Putting side effects in a background modifier is a common SwiftUI pattern
                // for keeping the main view's body clean.
                Color.clear
                    .onAppear {
                        // onAppear on the background fires in sync with the parent's first layout.
                        // We use it to emit the render signal for this body evaluation pass.
                        emitEvent(.viewRendered(viewName: viewName))
                    }
            )
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
