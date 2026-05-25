import SwiftUI

struct SettingsView: View {
    @AppStorage("scanDownloads") private var scanDownloads = true
    @AppStorage("scanDesktop") private var scanDesktop = true
    @AppStorage("scanDocuments") private var scanDocuments = false
    @AppStorage("showProtectedItems") private var showProtectedItems = false
    @AppStorage("defaultSelectLowRisk") private var defaultSelectLowRisk = true
    @AppStorage("excludedPaths") private var excludedPaths = ""

    var body: some View {
        Form {
            Section("Default Scan Roots") {
                Toggle("Downloads", isOn: $scanDownloads)
                Toggle("Desktop", isOn: $scanDesktop)
                Toggle("Documents", isOn: $scanDocuments)
            }

            Section("Safety") {
                Toggle("Show protected items in diagnostics", isOn: $showProtectedItems)
                Toggle("Select low-risk Trash candidates by default", isOn: $defaultSelectLowRisk)
                TextField("Excluded paths", text: $excludedPaths, axis: .vertical)
                    .lineLimit(3, reservesSpace: true)
                Text("MacTidy moves selected items to Trash after confirmation. Permanent deletion and privileged system changes are not part of this MVP.")
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .formStyle(.grouped)
        .padding(24)
        .frame(width: 460)
    }
}
