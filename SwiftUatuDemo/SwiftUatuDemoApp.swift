//
//  SwiftUatuDemoApp.swift
//  SwiftUatuDemo
//
//  Created by Meet Brahmbhatt on 04/07/26.
//

import SwiftUI
import SwiftUatu

@main
struct SwiftUatuDemoApp: App {

    @StateObject private var uatu = Uatu()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(uatu)
                .uatuOverlay(uatu: uatu)
                .task { await uatu.start() }
        }
    }
}
