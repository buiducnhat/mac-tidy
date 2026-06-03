import AppKit
import MacTidyCore
import SwiftUI

struct ApplicationsView: View {
    @Bindable var store: ApplicationsStore
    @State private var searchText = ""
    @State private var sourceFilter: ApplicationSourceFilter = .all
    @State private var isConfirmingUninstall = false

    private var filteredApplications: [InstalledApplication] {
        let term = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        return store.applications.filter { application in
            sourceFilter.includes(application)
        }.filter { application in
            guard !term.isEmpty else { return true }
            return application.displayName.localizedCaseInsensitiveContains(term)
            || (application.bundleIdentifier?.localizedCaseInsensitiveContains(term) ?? false)
            || application.url.path.localizedCaseInsensitiveContains(term)
        }
    }

    private var canUninstall: Bool {
        guard let application = store.selectedApplication else { return false }
        return !store.isBusy && application.isUninstallable && !store.selectedUninstallItems.isEmpty
    }

    var body: some View {
        VStack(spacing: 0) {
            header

            Divider()

            if store.applications.isEmpty {
                emptyState
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                VSplitView {
                    applicationTable
                        .frame(minHeight: 260)

                    reviewPanel
                        .frame(minHeight: 280)
                }
            }
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    store.scanApplications()
                } label: {
                    Label(store.applications.isEmpty ? "Scan" : "Rescan", systemImage: "arrow.clockwise")
                }
                .disabled(store.isBusy)
            }

            ToolbarItem(placement: .confirmationAction) {
                Button(role: .destructive) {
                    isConfirmingUninstall = true
                } label: {
                    Label("Move to Trash", systemImage: "trash")
                }
                .disabled(!canUninstall)
            }
        }
        .confirmationDialog(
            "Move selected application items to Trash?",
            isPresented: $isConfirmingUninstall,
            titleVisibility: .visible
        ) {
            Button("Move \(store.selectedUninstallItems.count) Item(s) to Trash", role: .destructive) {
                store.uninstallSelectedItems()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Selected size: \(ByteFormatter.string(from: store.selectedBytes)). Items are moved to Finder Trash and can be recovered there.")
        }
        .task {
            if store.applications.isEmpty && store.state == .idle {
                store.scanApplications()
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Text("Applications")
                    .font(.title2.weight(.semibold))
                Text(countText)
                    .foregroundStyle(.secondary)
                Spacer()
                if store.isBusy {
                    ProgressView()
                        .controlSize(.small)
                }
            }

            if let message = statusMessage {
                Text(message)
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }

            HStack(spacing: 12) {
                Picker("Application Source", selection: $sourceFilter) {
                    ForEach(ApplicationSourceFilter.allCases) { filter in
                        Text(filter.title).tag(filter)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 270)

                TextField("Search applications", text: $searchText)
                    .textFieldStyle(.roundedBorder)
                    .frame(maxWidth: 260)

                Button {
                    store.scanApplications()
                } label: {
                    Label("Rescan", systemImage: "arrow.clockwise")
                }
                .disabled(store.isBusy)

                Spacer()
            }
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 12)
        .background(.bar)
    }

    private var applicationTable: some View {
        Table(filteredApplications, selection: $store.selectedApplicationID) {
            TableColumn("Name") { application in
                HStack(spacing: 8) {
                    ApplicationIconView(url: application.url, size: 18)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(application.displayName)
                            .lineLimit(1)
                        Text(application.bundleIdentifier ?? PathDisplay.abbreviated(application.url))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }
            }

            TableColumn("Version") { application in
                Text(application.version ?? "Unknown")
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            .width(min: 90, ideal: 120)

            TableColumn("Size") { application in
                Text(ByteFormatter.string(from: application.size))
                    .monospacedDigit()
                    .foregroundStyle(.secondary)
            }
            .width(min: 90, ideal: 110)

            TableColumn("Modified") { application in
                Text(Self.dateFormatter.string(from: application.lastModified))
                    .foregroundStyle(.secondary)
            }
            .width(min: 110, ideal: 130)

            TableColumn("Status") { application in
                EligibilityBadge(isUninstallable: application.isUninstallable)
            }
            .width(min: 110, ideal: 130)
        }
        .contextMenu(forSelectionType: InstalledApplication.ID.self) { selection in
            if let id = selection.first, let application = store.applications.first(where: { $0.id == id }) {
                Button("Reveal in Finder") {
                    store.reveal(application)
                }
            }
        }
        .onChange(of: store.selectedApplicationID) { _, id in
            store.selectApplication(id.flatMap { selectedID in
                store.applications.first { $0.id == selectedID }
            })
        }
    }

    @ViewBuilder
    private var reviewPanel: some View {
        if let application = store.selectedApplication {
            VStack(alignment: .leading, spacing: 0) {
                selectedApplicationHeader(application)
                    .padding(16)

                Divider()

                if store.state == .loadingReview {
                    loadingReviewState
                } else {
                    uninstallItemsTable
                }

                Divider()

                reviewActionBar(application)
                    .padding(12)
            }
        } else {
            ContentUnavailableView("No Application Selected", systemImage: "app.dashed")
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    private func selectedApplicationHeader(_ application: InstalledApplication) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                ApplicationIconView(url: application.url, size: 34)
                VStack(alignment: .leading, spacing: 2) {
                    Text(application.displayName)
                        .font(.headline)
                        .lineLimit(1)
                    Text(application.bundleIdentifier ?? "No bundle identifier")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                Spacer()
                EligibilityBadge(isUninstallable: application.isUninstallable)
            }

            Grid(alignment: .leading, horizontalSpacing: 12, verticalSpacing: 6) {
                GridRow {
                    Text("Version")
                        .foregroundStyle(.secondary)
                    Text(application.version ?? "Unknown")
                }
                GridRow {
                    Text("Size")
                        .foregroundStyle(.secondary)
                    Text(ByteFormatter.string(from: application.size))
                }
                GridRow {
                    Text("Path")
                        .foregroundStyle(.secondary)
                    Text(PathDisplay.abbreviated(application.url))
                        .lineLimit(1)
                        .truncationMode(.middle)
                }
            }
            .font(.callout)

            if !application.isUninstallable {
                Text("This app is shown for inventory only and cannot be uninstalled from MacTidy.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private var uninstallItemsTable: some View {
        Table(store.uninstallItems) {
            TableColumn("") { item in
                Toggle("", isOn: Binding(
                    get: { store.selectedUninstallItemIDs.contains(item.id) },
                    set: { store.toggleUninstallItem(item, isSelected: $0) }
                ))
                .labelsHidden()
                .disabled(item.cleanupPolicy == .blocked || store.isBusy)
            }
            .width(32)

            TableColumn("Item") { item in
                VStack(alignment: .leading, spacing: 2) {
                    Text(item.name)
                        .lineLimit(1)
                    Text(PathDisplay.abbreviated(item.url))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }
            }

            TableColumn("Kind") { item in
                Text(item.kind.title)
                    .foregroundStyle(.secondary)
            }
            .width(min: 90, ideal: 110)

            TableColumn("Size") { item in
                Text(ByteFormatter.string(from: item.size))
                    .monospacedDigit()
            }
            .width(min: 80, ideal: 100)

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

    private var loadingReviewState: some View {
        VStack(spacing: 12) {
            ProgressView()
                .controlSize(.regular)
            Text("Loading related data")
                .font(.headline)
            Text("MacTidy is scanning user Library locations for reviewable app data.")
                .font(.callout)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(24)
    }

    private func reviewActionBar(_ application: InstalledApplication) -> some View {
        HStack(spacing: 10) {
            VStack(alignment: .leading, spacing: 2) {
                Text("\(store.selectedUninstallItems.count) selected")
                    .font(.headline)
                Text(ByteFormatter.string(from: store.selectedBytes))
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Button {
                store.reveal(application)
            } label: {
                Label("Reveal", systemImage: "finder")
            }
            .disabled(store.isBusy)

            Button(role: .destructive) {
                isConfirmingUninstall = true
            } label: {
                Label("Move to Trash", systemImage: "trash")
            }
            .disabled(!canUninstall)
        }
    }

    private var emptyState: some View {
        ContentUnavailableView {
            Label(emptyTitle, systemImage: "app.dashed")
        } description: {
            Text(emptyDescription)
        } actions: {
            Button {
                store.scanApplications()
            } label: {
                Label("Scan Applications", systemImage: "magnifyingglass")
            }
            .disabled(store.isBusy)
        }
    }

    private var countText: String {
        if filteredApplications.count == store.applications.count {
            return "\(store.applications.count)"
        }
        return "\(filteredApplications.count) of \(store.applications.count)"
    }

    private var statusMessage: String? {
        if !store.results.isEmpty {
            return resultSummary
        }

        switch store.state {
        case .scanning:
            return "Scanning local application folders."
        case .loadingReview:
            return "Loading uninstall review items."
        case .failed(let message):
            return message
        default:
            return nil
        }
    }

    private var emptyTitle: String {
        switch store.state {
        case .scanning: "Scanning"
        case .failed: "Scan Failed"
        default: "No Applications"
        }
    }

    private var emptyDescription: String {
        switch store.state {
        case .scanning: "Installed apps will appear when the scan completes."
        case .failed(let message): message
        default: "Run a scan to review installed local app bundles."
        }
    }

    private var resultSummary: String {
        let moved = store.results.filter { $0.status == .movedToTrash }.count
        let refused = store.results.filter { $0.status == .refused }.count
        let failed = store.results.filter { $0.status == .failed }.count
        return "Moved \(moved) item(s) to Trash. Refused \(refused). Failed \(failed)."
    }

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }()
}

private enum ApplicationSourceFilter: String, CaseIterable, Identifiable {
    case all
    case userInstalled
    case native

    var id: String { rawValue }

    var title: String {
        switch self {
        case .all: "All"
        case .userInstalled: "User Apps"
        case .native: "Native"
        }
    }

    func includes(_ application: InstalledApplication) -> Bool {
        switch self {
        case .all:
            return true
        case .userInstalled:
            return !isNative(application)
        case .native:
            return isNative(application)
        }
    }

    private func isNative(_ application: InstalledApplication) -> Bool {
        application.sourceRoot.path == "/System/Applications"
            || ProtectedPathRules.isProtected(application.sourceRoot)
            || (application.bundleIdentifier?.hasPrefix("com.apple.") ?? false)
    }
}

private struct ApplicationIconView: View {
    let url: URL
    let size: CGFloat

    var body: some View {
        Image(nsImage: NSWorkspace.shared.icon(forFile: url.path))
            .resizable()
            .scaledToFit()
            .frame(width: size, height: size)
    }
}

private struct EligibilityBadge: View {
    let isUninstallable: Bool

    var body: some View {
        Text(isUninstallable ? "Uninstallable" : "Inventory")
            .font(.caption.weight(.semibold))
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(.quaternary, in: Capsule())
            .foregroundStyle(isUninstallable ? .primary : .secondary)
    }
}

private extension DateFormatter {
    func string(from date: Date?) -> String {
        guard let date else { return "Unknown" }
        return string(from: date)
    }
}
