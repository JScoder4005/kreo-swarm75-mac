import KreoUI
import SwiftUI

@main
struct SwarmGlowApp: App {
    @StateObject private var state = AppState()

    var body: some Scene {
        // A normal window and Dock icon, so the app is easy to find even when the
        // menu-bar icon is hidden behind the notch.
        Window("SwarmGlow", id: "main") {
            MenuView().environmentObject(state)
        }
        .windowResizability(.contentSize)

        MenuBarExtra("SwarmGlow", systemImage: "keyboard") {
            MenuView().environmentObject(state)
        }
        .menuBarExtraStyle(.window)
    }
}
