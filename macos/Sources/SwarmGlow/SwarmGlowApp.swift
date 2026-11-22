import AppKit
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
                .onAppear(perform: captureIfRequested)
        }
        .windowResizability(.contentSize)

        MenuBarExtra("SwarmGlow", systemImage: "keyboard") {
            MenuView().environmentObject(state)
        }
        .menuBarExtraStyle(.window)
    }

    /// `SwarmGlow --capture <file.png>` saves the live window (title bar included) for the README.
    /// An app may always draw its own window, so this needs no Screen Recording permission.
    private func captureIfRequested() {
        let args = CommandLine.arguments
        guard let i = args.firstIndex(of: "--capture"), i + 1 < args.count else { return }
        let url = URL(fileURLWithPath: args[i + 1])
        if args.contains("--light") { NSApp.appearance = NSAppearance(named: .aqua) }
        if args.contains("--dark") { NSApp.appearance = NSAppearance(named: .darkAqua) }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            guard let frame = NSApp.windows.first(where: { $0.title == "SwarmGlow" && $0.isVisible })?.contentView?.superview,
                  let rep = frame.bitmapImageRepForCachingDisplay(in: frame.bounds) else { return }
            frame.cacheDisplay(in: frame.bounds, to: rep)
            try? rep.representation(using: .png, properties: [:])?.write(to: url)
        }
    }
}
