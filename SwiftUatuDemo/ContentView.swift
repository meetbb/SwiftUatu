//
//  ContentView.swift
//  SwiftUatuDemo
//
//  Created by Meet Brahmbhatt on 04/07/26.
//

import SwiftUI
import SwiftUatu

struct ContentView: View {

    @EnvironmentObject var uatu: Uatu

    var body: some View {
        // `let _ = uatu.trackRender(...)` is the correct way to count body evaluations.
        // SwiftUI calls this body every time ContentView re-renders, so the count stays accurate.
        let _ = uatu.trackRender("ContentView")

        return VStack(spacing: 24) {
            Text("SwiftUatu Demo")
                .font(.title2.bold())

            CounterView()
                .trackWithUatu(name: "CounterView", eventBus: uatu.eventBus)

            StaticView()
                .trackWithUatu(name: "StaticView", eventBus: uatu.eventBus)

            ToggledView()
                .trackWithUatu(name: "ToggledView", eventBus: uatu.eventBus)
        }
        .padding()
    }
}

// MARK: - CounterView
// Increments a counter every second → re-renders every second.
// Watch the overlay: this view's count climbs by 1 each second.
struct CounterView: View {

    @EnvironmentObject var uatu: Uatu
    @State private var count = 0

    var body: some View {
        let _ = uatu.trackRender("CounterView")

        return VStack(spacing: 8) {
            Text("CounterView")
                .font(.caption)
                .foregroundColor(.secondary)
            Text("\(count)")
                .font(.system(size: 48, weight: .bold, design: .monospaced))
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.blue.opacity(0.1))
        .cornerRadius(12)
        .onAppear {
            Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
                count += 1
            }
        }
    }
}

// MARK: - StaticView
// No state, no bindings → renders exactly once.
// The overlay should show this permanently at 1×.
struct StaticView: View {

    @EnvironmentObject var uatu: Uatu

    var body: some View {
        let _ = uatu.trackRender("StaticView")

        return VStack(spacing: 8) {
            Text("StaticView")
                .font(.caption)
                .foregroundColor(.secondary)
            Text("I never re-render.")
                .font(.headline)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.green.opacity(0.1))
        .cornerRadius(12)
    }
}

// MARK: - ToggledView
// Toggle it on/off to see its render count bump each time it reappears.
struct ToggledView: View {

    @EnvironmentObject var uatu: Uatu
    @State private var isVisible = true

    var body: some View {
        let _ = uatu.trackRender("ToggledView")

        return VStack(spacing: 8) {
            Toggle("ToggledView", isOn: $isVisible)
                .font(.caption)
                .foregroundColor(.secondary)
            if isVisible {
                Text("I appear and disappear.")
                    .font(.headline)
                    .transition(.opacity)
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.orange.opacity(0.1))
        .cornerRadius(12)
        .animation(.easeInOut, value: isVisible)
    }
}

#Preview {
    ContentView()
        .environmentObject(Uatu())
}
