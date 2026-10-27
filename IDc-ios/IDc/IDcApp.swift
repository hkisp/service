import SwiftUI

@main
struct IDcApp: App {
    @StateObject private var store = NodeStore()
    @StateObject private var vpn = VPNManager()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(store)
                .environmentObject(vpn)
                .preferredColorScheme(.dark)
        }
    }
}
