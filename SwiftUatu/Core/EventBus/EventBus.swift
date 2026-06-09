//
//  EventBus.swift
//  SwiftUatu
//
//  Created by Meet Brahmbhatt on 09/06/26.
//

import Foundation

/**
    The EventBus has one job: receive events and fan them out to anyone who's listening.
    It sits between the Instrumentation layer (which produces events) and the Collectors (which consume them).
    Neither side knows about the other – they only know about the bus.
    
    Why an actor?
    Events can be emitted from many places simultaneously – a scroll, a render, a lifecycle change all
    happening at the same time. An actor gives you thread-safe access without manual locking. The Swift
    concurrency runtime handles the serialization for you.
 
    Two operations
    The bus really only needs two things:
    publish – something happened, here's the events. Called by the Instrumentation layer. Fire and forget.
    subscribe – I want to hear about events. Called by each Collector when it's initialized. The collector passes
    a closure, and the bus calls it every time a new event arrives.
 
    Subscriber model
    Each subscriber is just a closure: (ProfilerEvent) async -> Void. The bus holds an array of these. When an event is published, it loops through all subscribers and calls each one with the event.
    This is intentionally simple for v0.1. In the future you could add filtering (a subscriber only receives certain event types) or back-pressure handling, but that's premature right now.
    
    What it does NOT do
    The bus doesn't transform events, store them, or make decisions about them. It's a pure delivery mechanism. Any intelligence lives in the collectors.
 */
public actor EventBus {
    private var subscribers: [(ProfilerEvent) async -> Void] = []
    
    public init() {}
    
    public func subscribe(_ subscriber: @escaping (ProfilerEvent) async -> Void) {
        subscribers.append(subscriber)
    }
    
    public func publish(_ event: ProfilerEvent) async {
        for subscriber in subscribers {
            await subscriber(event)
        }
    }
}
