# SwiftUatu — Interview Questions

A running list of important and difficult questions covering the concepts, design decisions,
and Swift/SwiftUI fundamentals used in building SwiftUatu. Updated at each milestone.

---

## v0.1.0 — Foundation

---

### SwiftUI Rendering

**Q1. What does it mean for a SwiftUI view to "re-render"?**

When SwiftUI re-renders a view, it calls that view's `body` property again to compute what the UI should look like. SwiftUI then compares the new result with the previous one and only updates the parts of the screen that changed.

A re-render is triggered when anything the view depends on changes — its `@State`, a `@Binding` passed from a parent, an `@EnvironmentObject`, or an `@ObservedObject`. If none of those change, SwiftUI skips re-evaluating the body entirely as an optimization.

---

**Q2. Why can't a `ViewModifier`'s body detect when the wrapped view re-renders?**

This is one of the core discoveries in SwiftUatu v0.1.0.

A `ViewModifier`'s `body(content:)` is only re-called when the modifier's own inputs change. If the modifier's properties (`viewName`, `eventBus`) are constants that never change, SwiftUI treats the modifier as stable and skips re-evaluating it — even if the wrapped view (like `CounterView`) is re-rendering every second due to its own state changes.

This is a deliberate SwiftUI optimization. The modifier wraps the view, but SwiftUI's identity and diffing system can update the inner view independently without re-evaluating every modifier in the chain.

In SwiftUatu, this means render tracking cannot happen inside the modifier. It must happen inline inside the view's own body — which is the only place that is guaranteed to execute on every re-render.

---

**Q3. What is the `let _ = uatu.trackRender("ViewName")` pattern and why do we use it?**

SwiftUI's `body` is a computed property that returns a view. Swift computed properties can only contain expressions that produce a return value — you can't write arbitrary statements inside them the way you can in a regular function.

However, `let _ = expression` is a valid Swift statement inside a computed property. It evaluates the expression and discards the result. Since `trackRender()` returns `Void`, this compiles cleanly.

```swift
var body: some View {
    let _ = uatu.trackRender("MyView")  // fires every time body is called
    return Text("Hello")
}
```

The reason we need this pattern: we want to run a side effect (emitting a render event) every time `body` is evaluated, without changing what the body returns. `let _ =` is the idiomatic SwiftUI way to do this.

---

### Swift Concurrency

**Q4. What is an `actor` in Swift and why does SwiftUatu use actors?**

An actor is a special type in Swift that protects its own mutable state from being accessed by multiple tasks at the same time. Only one task can execute inside an actor at a time — the Swift runtime enforces this automatically, so you don't need to write manual locks or dispatch queues.

SwiftUatu uses actors in three places:

- `EventBus` — events can be published from many places simultaneously (a render here, a lifecycle event there). Making it an actor ensures all subscriptions and publish calls happen safely without data races.
- `MetricsStore` — render counts are written by the collector and read by the overlay, potentially at the same time. The actor serializes these accesses.
- `RenderCollector` — it holds references to both `EventBus` and `MetricsStore` and is called from async closures. The actor keeps it safe.

The key benefit: you get thread safety for free, without writing a single lock.

---

**Q5. What does `@MainActor` do, and why is `Uatu` marked with it?**

`@MainActor` is a global actor that guarantees all code runs on the main thread. In iOS, all UI updates must happen on the main thread. If you touch the UI from a background thread, you get undefined behavior or a crash.

`Uatu` is marked `@MainActor` because:
1. It conforms to `ObservableObject`, which SwiftUI uses for data binding — SwiftUI expects this to be on the main thread.
2. It is held as a `@StateObject` in the app, and `@StateObject` properties are accessed on the main thread.
3. The `trackRender()` method is called from inside SwiftUI view bodies, which always run on the main thread.

Marking `Uatu` as `@MainActor` means the compiler enforces that all its methods are called from the main thread, and warns you at compile time if you try to call it from a background context.

---

**Q6. Why do we use `Task { await eventBus.publish(event) }` instead of directly calling `publish`?**

`EventBus.publish()` is an `async` function — calling it requires `await`. But `Uatu.trackRender()` and the lifecycle closures in `UatuViewModifier` are synchronous. You can't use `await` in a synchronous context.

`Task { }` creates a new concurrent task that runs asynchronously. By wrapping the `await` inside a `Task`, we fire the publish call and immediately return — "fire and forget." The task runs in the background without blocking the view's body or the UI thread.

This is safe because `ProfilerEvent` is a `Sendable` value type (a struct with all `Sendable` properties), so capturing it in the Task closure doesn't create any shared mutable state.

---

**Q7. What does `Sendable` mean and why does `ProfilerEvent` need to conform to it?**

`Sendable` is a Swift protocol that marks a type as safe to pass across concurrency boundaries (between actors, tasks, and threads). A type is `Sendable` if it cannot cause data races when shared — typically because it is immutable or a value type.

`ProfilerEvent` is a struct with:
- `UUID` — a struct, Sendable
- `ProfilerEventType` — an enum with String associated values, Sendable
- `ProfilerEventSource` — a struct with a String, Sendable
- `Date` — a struct, Sendable

All fields are Sendable value types, so `ProfilerEvent` is `Sendable`. This matters because we capture `ProfilerEvent` inside a `Task { }` closure and pass it to the `EventBus` actor. Without `Sendable`, the compiler would flag this as a potential data race.

---

**Q8. What is a retain cycle and how does `[weak self]` in `RenderCollector.start()` prevent one?**

A retain cycle happens when two objects hold strong references to each other, so neither can ever be deallocated — a memory leak.

In `RenderCollector.start()`:

```swift
await eventBus.subscribe { [weak self] event in
    await self?.handle(event)
}
```

The ownership chain is: `RenderCollector` owns `EventBus` → `EventBus` holds the subscriber closure → the closure captures `self` (RenderCollector).

If the closure captured `self` strongly, `RenderCollector` would own `EventBus`, which would own a reference back to `RenderCollector` — a cycle. Neither would ever be freed.

`[weak self]` makes the closure hold a weak reference to `RenderCollector`. Weak references don't count toward ownership. If `RenderCollector` is deallocated, `self` inside the closure becomes `nil`, and `self?.handle(event)` safely does nothing. No cycle, no leak.

---

### Architecture and Design

**Q9. What is the EventBus pattern and what problem does it solve in SwiftUatu?**

The EventBus is a publish/subscribe (pub/sub) system. Publishers emit events without knowing who is listening. Subscribers receive events without knowing who emitted them. The bus is the only shared piece — it decouples the two sides completely.

In SwiftUatu, this solves a specific problem: the instrumentation layer (the part that detects renders and lifecycle events) should not know anything about the metrics layer (the part that computes and stores metrics). If `UatuViewModifier` directly called `metricsStore.incrementRenderCount()`, the instrumentation would be tightly coupled to the metrics system. Adding a new collector (say, for FPS) would require changing the modifier.

With EventBus:
- The modifier just publishes an event. It doesn't know or care what happens next.
- Collectors subscribe and handle events independently.
- Adding a new collector requires zero changes to the instrumentation layer.

---

**Q10. Why is `MetricsStore` the single source of truth instead of letting each collector hold its own data?**

If each collector stored its own results, any consumer — the overlay, the analysis engine, a future export system — would need to know about every collector separately to read data. Adding a new collector would require updating every consumer.

With `MetricsStore` as the single source of truth:
- Collectors write to one place.
- Consumers read from one place.
- Neither side knows about the other.

This is the same principle behind Redux or any unidirectional data flow architecture. The store is the stable, well-known location for state. Everything else is just reading from or writing to it.

---

**Q11. Why is `UatuConfig` a struct rather than a class?**

`UatuConfig` is pure configuration — it just holds values. There is no identity, no shared state, and no need for inheritance. A struct is the right choice because:

1. It is a value type. When you pass it to `Uatu.init(config:)`, a copy is made. `Uatu` owns its own copy and no one else can mutate it externally.
2. It is `Sendable` by default (all its properties are value types), so it can be passed safely across concurrency boundaries.
3. It has no behavior — just data. Structs are lighter and more predictable than classes for this use case.

If `UatuConfig` were a class, you could hold a reference to it and change properties after passing it to `Uatu`, which could cause confusing, hard-to-debug behavior.

---

**Q12. Why does `Uatu` conform to `ObservableObject` instead of being a plain class or an actor?**

`Uatu` is the object the app holds onto and passes into the SwiftUI environment. SwiftUI's `@StateObject` and `@EnvironmentObject` require `ObservableObject`. Without it, SwiftUI has no mechanism to know when to update views that depend on `Uatu`.

It can't be an actor because `ObservableObject` requires publishing changes via `objectWillChange` on the main thread, and actors don't naturally integrate with SwiftUI's observation system. Making it a `@MainActor` class gives us the thread safety of always running on the main thread, while letting it conform to `ObservableObject` and participate in SwiftUI's data binding system.

---

**Q13. The overlay polls MetricsStore every 0.5 seconds. Why not make MetricsStore observable instead?**

Making `MetricsStore` directly observable would mean every render event — potentially hundreds per second — would trigger a SwiftUI re-render of the overlay. That would add significant overhead and potentially cause the overlay's own render to show up as noise in the metrics.

Polling every 0.5 seconds is a deliberate throttle. The overlay only updates twice per second regardless of how many events arrive. This keeps the overhead low and the display readable. The small delay (up to 0.5s) is invisible to a developer watching the HUD.

This is a common pattern in profiling tools: collect at high frequency, display at a lower, human-readable frequency.

---

**Q14. What is `guard config.isEnabled else { return }` in `Uatu.start()` and `trackRender()` doing, and why is it the right place to check?**

When `isEnabled` is `false`, we want the framework to be a complete no-op — zero overhead. By checking at the earliest entry points:

- `start()` — if disabled, no collectors are started, so the `EventBus` has no subscribers. Any event published goes nowhere (the publish loop iterates over an empty array).
- `trackRender()` — if disabled, we return immediately without creating any `Task` or `ProfilerEvent`.

This means disabled mode costs essentially nothing: one boolean check per call site. The check is at the right level because it's in the public API, before any heap allocation or async work happens.

Checking inside the collector or the store would be too late — we'd still create events and dispatch tasks, then discard them deep in the pipeline.

---

**Q15. How does the `UatuOverlayView` avoid causing a memory leak or a dangling task?**

The overlay uses SwiftUI's `.task { }` modifier, which ties the lifetime of the async task to the lifetime of the view. When the view leaves the screen (e.g., the app is killed, or the overlay is hidden), SwiftUI automatically cancels the task.

Inside the task, we check `Task.isCancelled` on each loop iteration:

```swift
while !Task.isCancelled {
    renderCounts = await metricsStore.allRenderCounts()
    try? await Task.sleep(nanoseconds: 500_000_000)
}
```

When SwiftUI cancels the task, `Task.isCancelled` becomes `true` on the next check and the loop exits cleanly. `try? await Task.sleep` also throws a `CancellationError` when cancelled, which we suppress with `try?` — this causes the sleep to exit early and the loop to check the cancellation flag immediately.

The result: no dangling background task, no memory leak, no polling after the view is gone.
