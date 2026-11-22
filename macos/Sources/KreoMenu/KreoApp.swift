import SwiftUI

@main
struct KreoApp: App {
    @StateObject private var state = AppState()

    var body: some Scene {
        // A normal window and Dock icon, so the app is easy to find even when the
        // menu-bar icon is hidden behind the notch.
        Window("Kreo", id: "main") {
            MenuView(link: state.link).environmentObject(state)
        }
        .windowResizability(.contentSize)

        MenuBarExtra("Kreo", systemImage: "keyboard") {
            MenuView(link: state.link).environmentObject(state)
        }
        .menuBarExtraStyle(.window)
    }
}
