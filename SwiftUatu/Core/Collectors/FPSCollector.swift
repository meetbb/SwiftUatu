//
//  FPSCollector.swift
//  SwiftUatu
//
//  Created by Meet Brahmbhatt on 06/07/26.
//

import QuartzCore

// FPSCollector measures the app's frame rate using CADisplayLink.
//
// CADisplayLink is a timer synchronized to the display's refresh cycle.
// The system calls our `tick` method once per frame — 60 times per second
// on standard displays, up to 120 times per second on ProMotion displays.
// We count those calls over a 1-second window to produce an FPS reading.
//
// Why not EventBus?
// FPS is a continuous sampled metric, not a discrete event. Routing 60
// updates per second through the EventBus would add unnecessary overhead.
// FPSCollector writes directly to MetricsStore instead.
//
// Why NSObject?
// CADisplayLink requires an @objc selector target, which requires NSObject.
//
// Why @MainActor?
// CADisplayLink runs on the main run loop (main thread). Marking the class
// @MainActor makes Swift's concurrency system aware of this, so all property
// accesses are considered main-thread-safe without additional synchronization.
@MainActor
public final class FPSCollector: NSObject {

    private let metricsStore: MetricsStore
    private var displayLink: CADisplayLink?

    // Counts frames within the current 1-second window.
    private var frameCount: Int = 0

    // Timestamp of when the current 1-second window started.
    // Zero means the first tick hasn't been recorded yet.
    private var windowStartTime: CFTimeInterval = 0

    public init(metricsStore: MetricsStore) {
        self.metricsStore = metricsStore
        super.init()
    }

    // Starts the display link. Call once from Uatu.start().
    public func start() {
        displayLink = CADisplayLink(target: self, selector: #selector(tick(_:)))
        displayLink?.add(to: .main, forMode: .common)
    }

    // Stops the display link and releases it.
    // Important: always call stop() before deallocating to prevent a dangling timer.
    public func stop() {
        displayLink?.invalidate()
        displayLink = nil
    }

    // MARK: - Private

    @objc private func tick(_ link: CADisplayLink) {
        // On the very first tick, initialise the window start time and return.
        // We don't count the first frame because we have no elapsed time yet.
        if windowStartTime == 0 {
            windowStartTime = link.timestamp
            return
        }

        frameCount += 1

        let elapsed = link.timestamp - windowStartTime

        // Once a full second has passed, compute and store FPS, then reset the window.
        if elapsed >= 1.0 {
            let fps = Double(frameCount) / elapsed
            frameCount = 0
            windowStartTime = link.timestamp

            // MetricsStore is a separate actor — hop to it asynchronously.
            Task {
                await metricsStore.updateFPS(fps)
            }
        }
    }
}
