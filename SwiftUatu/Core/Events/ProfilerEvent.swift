//
//  ProfilerEvent.swift
//  SwiftUatu
//
//  Created by Meet Brahmbhatt on 09/06/26.
//

import Foundation

// MARK: - ProfilerEventType
// Describes what happened in the app.
// Each case represents a distinct runtime signal.
// Associated values carry context specific to that signal.
public enum ProfilerEventType: Sendable {
    // View Lifecycle
    case viewAppeared(viewName: String)
    case viewDisappeared(viewName: String)
    case viewRendered(viewName: String)
}

// MARK: - ProfilerEventSource

// Identifies where an event originated.
public struct ProfilerEventSource: Sendable {

    // The name of the SwiftUI view that produced this event.
    public let viewName: String

    public init(viewName: String) {
        self.viewName = viewName
    }
}

// MARK: - ProfilerEvent
// A single runtime signal captured from a SwiftUI application.
//
// ProfilerEvent is the fundamental unit of data in SwiftUatu.
// Every metric the framework produces is derived from a stream of these events.
//
// Events are immutable value types. Once created, they are never modified.
// They travel through the EventBus to be consumed by metric collectors.
public struct ProfilerEvent: Sendable {

    /// Unique identifier for this event.
    public let id: UUID

    public let type: ProfilerEventType
    
    public let source: ProfilerEventSource

    public let timestamp: Date

    public init(
        id: UUID = UUID(),
        type: ProfilerEventType,
        source: ProfilerEventSource,
        timestamp: Date = Date()
    ) {
        self.id = id
        self.type = type
        self.source = source
        self.timestamp = timestamp
    }

}
