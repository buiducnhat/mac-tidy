import MacTidyCore
import SwiftUI

struct AnalyzeView: View {
    @Bindable var scanStore: ScanStore

    var body: some View {
        VStack(spacing: 0) {
            ScanControlsView(scanStore: scanStore)
                .padding(20)

            Divider()

            if scanStore.items.isEmpty {
                AnalyzeEmptyState(state: scanStore.state)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                VStack(spacing: 0) {
                    if !scanStore.diagnostics.isEmpty {
                        DiagnosticsStrip(diagnostics: scanStore.diagnostics)
                    }
                    ScanResultsTable(items: scanStore.items)
                }
            }
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    scanStore.isScanning ? scanStore.cancel() : scanStore.scan()
                } label: {
                    Label(scanStore.isScanning ? "Cancel" : "Scan", systemImage: scanStore.isScanning ? "stop" : "play")
                }
            }
        }
    }
}

private struct DiagnosticsStrip: View {
    let diagnostics: [ScanDiagnostic]

    var body: some View {
        HStack {
            Label("\(diagnostics.count) scan diagnostic(s)", systemImage: "exclamationmark.triangle")
            Spacer()
            Text(diagnostics.first?.message ?? "Some paths could not be scanned.")
                .lineLimit(1)
        }
        .font(.callout)
        .foregroundStyle(.orange)
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(.quaternary)
    }
}

private struct ScanControlsView: View {
    @Bindable var scanStore: ScanStore

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Analyze")
                        .font(.title2.weight(.semibold))
                    Text(statusText)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Button {
                    scanStore.cancel()
                } label: {
                    Label("Cancel", systemImage: "stop")
                }
                .disabled(!scanStore.isScanning)

                Button {
                    scanStore.scan()
                } label: {
                    Label(scanStore.items.isEmpty ? "Scan" : "Rescan", systemImage: "arrow.clockwise")
                }
                .keyboardShortcut("r", modifiers: .command)
                .disabled(scanStore.isScanning)
            }

            FlowLayout {
                ForEach(scanStore.roots) { root in
                    Toggle(isOn: Binding(
                        get: { scanStore.selectedRootIDs.contains(root.id) },
                        set: { scanStore.toggleRoot(root, isSelected: $0) }
                    )) {
                        Text(root.title)
                    }
                    .toggleStyle(.checkbox)
                    .disabled(scanStore.isScanning)
                }
            }
        }
    }

    private var statusText: String {
        switch scanStore.state {
        case .idle:
            "Select user-owned roots and run a non-destructive scan."
        case .scanning:
            "Scanning selected roots..."
        case .complete:
            "Scan complete."
        case .cancelled:
            "Scan cancelled."
        case .failed(let message):
            message
        }
    }
}

private struct AnalyzeEmptyState: View {
    let state: ScanStore.State

    var body: some View {
        ContentUnavailableView {
            Label(title, systemImage: systemImage)
        } description: {
            Text(description)
        }
    }

    private var title: String {
        switch state {
        case .scanning: "Scanning"
        case .cancelled: "Scan Cancelled"
        case .failed: "Scan Not Started"
        default: "No Results"
        }
    }

    private var systemImage: String {
        switch state {
        case .cancelled: "stop.circle"
        case .failed: "exclamationmark.triangle"
        default: "magnifyingglass.circle"
        }
    }

    private var description: String {
        switch state {
        case .scanning: "Results will appear as soon as the scan completes."
        case .cancelled: "Run the scan again when ready."
        case .failed(let message): message
        default: "Run a scan to review folders and files by size."
        }
    }
}

private struct ScanResultsTable: View {
    let items: [ScanItem]

    var body: some View {
        Table(items) {
            TableColumn("Name") { item in
                VStack(alignment: .leading, spacing: 2) {
                    Text(item.name)
                        .lineLimit(1)
                    Text(PathDisplay.abbreviated(item.url))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }

            TableColumn("Size") { item in
                Text(ByteFormatter.string(from: item.size))
                    .monospacedDigit()
            }
            .width(min: 90, ideal: 110)

            TableColumn("Category") { item in
                Text(item.category.title)
            }
            .width(min: 90, ideal: 110)

            TableColumn("Risk") { item in
                Text(item.risk.title)
            }
            .width(min: 70, ideal: 90)

            TableColumn("Diagnostics") { item in
                if item.diagnostics.isEmpty {
                    Text("")
                        .foregroundStyle(.secondary)
                } else {
                    Text("\(item.diagnostics.count)")
                        .foregroundStyle(.orange)
                }
            }
            .width(min: 80, ideal: 100)
        }
    }
}

private struct FlowLayout<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        HStack(spacing: 16) {
            content
        }
    }
}
