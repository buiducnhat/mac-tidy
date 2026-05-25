import AppKit
import SwiftUI

@main
struct MacTidyApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @State private var appState = AppSceneState()

    var body: some Scene {
        WindowGroup("MacTidy", id: "main") {
            RootView(appState: appState)
                .frame(minWidth: 960, minHeight: 620)
        }
        .commands {
            CommandGroup(replacing: .newItem) { }
            CommandMenu("Actions") {
                Button("Scan or Rescan") {
                    appState.performPrimaryScan()
                }
                .keyboardShortcut("r", modifiers: .command)

                Button("Cancel Analyze Scan") {
                    appState.scanStore.cancel()
                }
                .keyboardShortcut(".", modifiers: .command)
                .disabled(!appState.scanStore.isScanning)

                Button("Move Selected to Trash") {
                    appState.performCleanup()
                }
                .keyboardShortcut(.delete, modifiers: .command)
                .disabled(!appState.canPerformCleanup)
            }
        }

        Settings {
            SettingsView()
        }
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
    }
}
