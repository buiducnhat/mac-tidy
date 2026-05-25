import MacTidyCore
import SwiftUI

struct CleanupReviewView: View {
    @Bindable var store: CleanupStore
    let title: String
    let subtitle: String
    let systemImage: String
    @State private var isConfirmingCleanup = false

    var body: some View {
        VStack(spacing: 0) {
            header
                .padding(20)

            Divider()

            if store.candidates.isEmpty {
                emptyState
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                Table(store.candidates) {
                    TableColumn("") { item in
                        Toggle("", isOn: Binding(
                            get: { store.selectedIDs.contains(item.id) },
                            set: { store.toggle(item, isSelected: $0) }
                        ))
                        .labelsHidden()
                    }
                    .width(32)

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

                    TableColumn("Risk") { item in
                        RiskBadge(risk: item.risk)
                    }
                    .width(min: 90, ideal: 110)

                    TableColumn("Reveal") { item in
                        Button {
                            store.reveal(item)
                        } label: {
                            Label("Reveal", systemImage: "finder")
                        }
                        .labelStyle(.iconOnly)
                        .help("Reveal in Finder")
                    }
                    .width(54)
                }
            }
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    store.scan()
                } label: {
                    Label(store.candidates.isEmpty ? "Scan" : "Rescan", systemImage: "arrow.clockwise")
                }
                .disabled(store.isBusy)
            }

            ToolbarItem(placement: .confirmationAction) {
                Button {
                    isConfirmingCleanup = true
                } label: {
                    Label("Move to Trash", systemImage: "trash")
                }
                .disabled(store.selectedItems.isEmpty || store.isBusy)
            }
        }
        .confirmationDialog(
            "Move selected items to Trash?",
            isPresented: $isConfirmingCleanup,
            titleVisibility: .visible
        ) {
            Button("Move \(store.selectedItems.count) Item(s) to Trash", role: .destructive) {
                store.cleanSelected()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Selected size: \(ByteFormatter.string(from: store.selectedBytes)). Items can be recovered from Finder Trash.")
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 12) {
                Image(systemName: systemImage)
                    .font(.system(size: 30, weight: .semibold))
                    .foregroundStyle(.tint)
                    .frame(width: 44, height: 44)

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.title2.weight(.semibold))
                    Text(subtitle)
                        .foregroundStyle(.secondary)
                }

                Spacer()
            }

            HStack(spacing: 18) {
                Label("\(store.candidates.count) candidates", systemImage: "list.bullet")
                Label("\(store.selectedItems.count) selected", systemImage: "checkmark.circle")
                Label(ByteFormatter.string(from: store.selectedBytes), systemImage: "externaldrive")
            }
            .font(.callout)
            .foregroundStyle(.secondary)

            if !store.results.isEmpty {
                Text(resultSummary)
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var emptyState: some View {
        ContentUnavailableView {
            Label(emptyTitle, systemImage: systemImage)
        } description: {
            Text(emptyDescription)
        } actions: {
            Button {
                store.scan()
            } label: {
                Label("Scan", systemImage: "magnifyingglass")
            }
            .disabled(store.isBusy)
        }
    }

    private var emptyTitle: String {
        switch store.state {
        case .scanning: "Scanning"
        case .cleaned: "Cleanup Complete"
        case .failed: "Scan Failed"
        default: "No Candidates"
        }
    }

    private var emptyDescription: String {
        switch store.state {
        case .scanning: "Candidates will appear when the scan completes."
        case .cleaned: resultSummary
        case .failed(let message): message
        default: "Run a scan to find reviewable cleanup candidates."
        }
    }

    private var resultSummary: String {
        let moved = store.results.filter { $0.status == .movedToTrash }.count
        let refused = store.results.filter { $0.status != .movedToTrash }.count
        return "Moved \(moved) item(s) to Trash. \(refused) item(s) were refused or failed."
    }
}

private struct RiskBadge: View {
    let risk: RiskLevel

    var body: some View {
        Text(risk.title)
            .font(.caption.weight(.semibold))
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(.quaternary, in: Capsule())
    }
}
