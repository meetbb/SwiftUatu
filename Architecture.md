# SwiftUatu Architecture

## Overview

SwiftUatu is a SwiftUI observability and diagnostics framework designed to help developers understand the runtime behavior of their applications.

The framework focuses on collecting, analyzing, and visualizing runtime signals such as:

* View lifecycle events
* View re-renders
* Frame rate metrics
* Memory usage
* CPU utilization
* Scroll performance
* State propagation
* Performance bottlenecks

SwiftUatu is inspired by the concept of Uatu the Watcher.

Its responsibility is to observe everything and interfere with nothing.

---

## Design Principles

### Non-Intrusive

SwiftUatu should require minimal code changes.

Example:

```swift
FeedView()
    .enableUatu()
```

### Low Overhead

The profiler must never become the performance bottleneck.

### SwiftUI First

SwiftUatu is built specifically for SwiftUI and its rendering model.

### Event Driven

Every metric originates from a runtime event.

### Extensible

New collectors and analyzers can be added without modifying the core architecture.

---

# High Level Architecture

```text
┌────────────────────────────┐
│      SwiftUI App           │
└──────────────┬─────────────┘
               │
               ▼
┌────────────────────────────┐
│ Instrumentation Layer      │
└──────────────┬─────────────┘
               │
               ▼
┌────────────────────────────┐
│ Event Bus                  │
└──────────────┬─────────────┘
               │
               ▼
┌────────────────────────────┐
│ Metrics Collectors         │
├────────────────────────────┤
│ FPS Collector              │
│ Memory Collector           │
│ CPU Collector              │
│ Render Collector           │
│ Scroll Collector           │
└──────────────┬─────────────┘
               │
               ▼
┌────────────────────────────┐
│ Metrics Store              │
└──────────────┬─────────────┘
               │
               ▼
┌────────────────────────────┐
│ Analysis Engine            │
└──────────────┬─────────────┘
               │
               ▼
┌────────────────────────────┐
│ Overlay & Reports          │
└────────────────────────────┘
```

---

# Core Components

## Instrumentation Layer

Responsible for capturing runtime events.

Examples:

* View appeared
* View disappeared
* View rendered
* Scroll started
* Scroll ended

Output:

```swift
ProfilerEvent
```

---

## Event Bus

Central communication channel.

Responsibilities:

* Decouple producers and consumers
* Support async event processing
* Enable future extensibility

Possible implementation:

```swift
actor EventBus
```

---

## Metrics Collectors

Collectors transform events into measurable metrics.

Examples:

### FPS Collector

Tracks:

* Current FPS
* Average FPS
* Dropped Frames

### Memory Collector

Tracks:

* Current Memory
* Peak Memory

### Render Collector

Tracks:

* Render Count
* Render Frequency

### Scroll Collector

Tracks:

* Scroll FPS
* Scroll Jank

---

## Metrics Store

Single source of truth for all collected metrics.

Responsibilities:

* Thread-safe storage
* Historical snapshots
* Aggregated statistics

Potential implementation:

```swift
actor MetricsStore
```

---

## Analysis Engine

Converts metrics into actionable diagnostics.

Examples:

* Excessive re-renders
* Update storms
* FPS degradation
* Memory spikes

Output:

```swift
DiagnosticWarning
```

---

## Overlay Engine

Displays diagnostics inside the running application.

Example:

FPS: 60
Memory: 145 MB
Warnings: 2

---

# Future Architecture

Future versions may include:

* State propagation graph
* Re-render reason analysis
* Signpost integration
* Performance report export
* CI/CD integration
* Xcode plugin support

---

# Goals

SwiftUatu is not intended to replace Instruments.

Its goal is to provide immediate and actionable performance insights directly within SwiftUI applications during development.
