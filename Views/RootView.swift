import SwiftUI

struct RootView: View {
    @Bindable var appState: AppSceneState

    var body: some View {
        NavigationSplitView {
            SidebarView(selection: $appState.selectedDestination)
                .navigationSplitViewColumnWidth(min: 240, ideal: 280, max: 320)
        } detail: {
            DetailView(appState: appState)
        }
        .toolbar {
            if appState.selectedDestination.isHomebrew {
                ToolbarItemGroup {
                    Button {
                        Task { await appState.brewStore.refreshAll() }
                    } label: {
                        Label("Refresh", systemImage: "arrow.clockwise")
                    }
                    .disabled(appState.brewStore.isLoading || appState.brewStore.isRunningCommand)

                    Button {
                        appState.runHomebrewUpdate()
                    } label: {
                        Label("Update", systemImage: "arrow.triangle.2.circlepath")
                    }
                    .disabled(appState.brewStore.isRunningCommand)
                }
            }
        }
        .overlay(alignment: .bottom) {
            if appState.selectedDestination.isHomebrew,
               let errorMessage = appState.brewStore.errorMessage {
                HomebrewErrorBanner(message: errorMessage) {
                    appState.brewStore.errorMessage = nil
                }
                .padding()
            }
        }
        .sheet(isPresented: Binding(
            get: { appState.fullDiskAccessStore.isRequestPresented },
            set: { appState.fullDiskAccessStore.isRequestPresented = $0 }
        )) {
            FullDiskAccessRequestView(store: appState.fullDiskAccessStore)
        }
        .task {
            appState.requestFullDiskAccessOnLaunchIfNeeded()
        }
        .buttonBorderShape(.roundedRectangle(radius: 8))
    }
}
