import SwiftUI

struct HomebrewPackagesView: View {
    let title: String
    let packages: [BrewPackage]
    @Binding var packageFilter: BrewPackageFilter
    @Bindable var store: BrewStore
    let emptyMessage: String

    private var filteredPackages: [BrewPackage] {
        packages.filter(packageFilter.includes)
    }

    private var selectedVisiblePackage: BrewPackage? {
        filteredPackages.first { $0.id == store.selectedPackageID }
    }

    var body: some View {
        VStack(spacing: 0) {
            HomebrewHeaderBar(title: title, count: filteredPackages.count, totalCount: packages.count, isBusy: store.isLoading || store.isRunningCommand) {
                Picker("Package Kind", selection: $packageFilter) {
                    ForEach(BrewPackageFilter.allCases) { filter in
                        Text(filter.rawValue).tag(filter)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 270)
            }

            if filteredPackages.isEmpty {
                ContentUnavailableView(packages.isEmpty ? emptyMessage : "No packages match this filter.", systemImage: "shippingbox")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                Table(filteredPackages, selection: $store.selectedPackageID) {
                    TableColumn("Name") { package in
                        HStack(spacing: 8) {
                            HomebrewPackageIconView(package: package, size: 16)
                            Text(package.title)
                                .lineLimit(1)
                            if package.showsDisplayName {
                                Text(package.name)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(1)
                            }
                        }
                    }
                    TableColumn("Kind") { package in
                        Text(package.kind.rawValue)
                            .foregroundStyle(.secondary)
                    }
                    .width(80)
                    TableColumn("Version") { package in
                        Text(package.versionSummary)
                            .lineLimit(1)
                            .foregroundStyle(package.isOutdated ? .orange : .secondary)
                    }
                    TableColumn("Installed") { package in
                        Text(BrewFormatters.formatPackageDate(package.installedAt))
                            .foregroundStyle(.secondary)
                    }
                    .width(110)
                    TableColumn("Last Used") { package in
                        Text(BrewFormatters.formatPackageDate(package.lastUsedAt))
                            .foregroundStyle(.secondary)
                    }
                    .width(110)
                    TableColumn("Size") { package in
                        Text(BrewFormatters.formatPackageSize(package.sizeBytes))
                            .foregroundStyle(.secondary)
                    }
                    .width(90)
                }
                .contextMenu(forSelectionType: BrewPackage.ID.self) { selection in
                    if let id = selection.first, let package = filteredPackage(id: id) {
                        packageMenu(for: package)
                    }
                } primaryAction: { selection in
                    if let id = selection.first, let package = filteredPackage(id: id) {
                        Task { await store.showInfo(for: package) }
                    }
                }
            }

            if let package = selectedVisiblePackage {
                HomebrewPackageActionBar(package: package, store: store)
            }

            if store.activeResult != nil {
                HomebrewCommandOutputView(result: store.activeResult, history: store.commandHistory) {
                    store.clearActiveResult()
                }
                    .padding(12)
                    .frame(maxHeight: 320)
            }
        }
        .sheet(item: $store.packageInfo) { info in
            HomebrewPackageInfoSheet(info: info) {
                store.closePackageInfo()
            }
        }
    }

    @ViewBuilder
    private func packageMenu(for package: BrewPackage) -> some View {
        Button("Show Info") {
            Task { await store.showInfo(for: package) }
        }
        Button("Upgrade") {
            Task { await store.upgrade(package) }
        }
        Button("Uninstall") {
            Task { await store.uninstall(package) }
        }
    }

    private func filteredPackage(id: BrewPackage.ID) -> BrewPackage? {
        filteredPackages.first { $0.id == id }
    }
}

struct HomebrewPackageInfoSheet: View {
    let info: BrewPackageInfo
    let close: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .center, spacing: 12) {
                HomebrewPackageIconView(package: info.package, size: 34)
                    .brewGlass(cornerRadius: 10)
                VStack(alignment: .leading, spacing: 2) {
                    Text(info.package.title)
                        .font(.title2.weight(.semibold))
                    if info.package.showsDisplayName {
                        Text(info.package.name)
                            .foregroundStyle(.secondary)
                    }
                    Text(info.headline)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                Spacer()
                Button(action: close) {
                    Image(systemName: "xmark")
                }
                .buttonStyle(.borderless)
                .keyboardShortcut(.cancelAction)
            }
            .padding(20)
            .background(.bar)

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    HomebrewInfoSummaryGrid(info: info)

                    if let description = info.description {
                        HomebrewInfoSectionView(title: "Description", content: description)
                    }

                    if let status = info.status {
                        HomebrewInfoSectionView(title: "Status", content: status)
                    }

                    ForEach(info.sections) { section in
                        HomebrewInfoSectionView(title: section.title, content: section.body)
                    }

                    Text(info.command)
                        .font(.system(.caption, design: .monospaced))
                        .foregroundStyle(.tertiary)
                        .textSelection(.enabled)
                }
                .padding(20)
            }
        }
        .frame(width: 720, height: 640)
    }
}

struct HomebrewPackageIconView: View {
    let package: BrewPackage
    let size: CGFloat

    var body: some View {
        Group {
            if let icon = CaskAppIconResolver.icon(for: package) {
                Image(nsImage: icon)
                    .resizable()
                    .scaledToFit()
            } else {
                Image(systemName: package.kind == .cask ? "macwindow" : "terminal")
                    .font(.system(size: max(12, size * 0.58)))
                    .foregroundStyle(.secondary)
            }
        }
        .frame(width: size, height: size)
    }
}

struct HomebrewInfoSummaryGrid: View {
    let info: BrewPackageInfo

    var body: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 180), spacing: 12)], spacing: 12) {
            HomebrewInfoSummaryItem(title: "Kind", value: info.package.kind.rawValue, systemImage: info.package.kind == .cask ? "macwindow" : "terminal")
            HomebrewInfoSummaryItem(title: "Version", value: info.package.versionSummary, systemImage: "number")
            HomebrewInfoSummaryItem(title: "Installed", value: BrewFormatters.formatPackageDate(info.package.installedAt), systemImage: "calendar")
            HomebrewInfoSummaryItem(title: "Last Used", value: BrewFormatters.formatPackageDate(info.package.lastUsedAt), systemImage: "clock")
            HomebrewInfoSummaryItem(title: "Size", value: BrewFormatters.formatPackageSize(info.package.sizeBytes), systemImage: "externaldrive")
            if let homepage = info.homepage {
                Link(destination: homepage) {
                    HomebrewInfoSummaryItem(title: "Homepage", value: homepage.host() ?? homepage.absoluteString, systemImage: "link")
                }
                .buttonStyle(.plain)
            }
        }
    }
}

struct HomebrewInfoSummaryItem: View {
    let title: String
    let value: String
    let systemImage: String

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: systemImage)
                .foregroundStyle(.secondary)
                .frame(width: 18)
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(value)
                    .lineLimit(2)
            }
            Spacer(minLength: 0)
        }
        .padding(12)
        .brewGlass(cornerRadius: 12)
    }
}

struct HomebrewInfoSectionView: View {
    let title: String
    let content: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
            Text(content)
                .font(.body)
                .foregroundStyle(.secondary)
                .textSelection(.enabled)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .brewGlass(cornerRadius: 12)
    }
}

struct HomebrewHeaderBar<Accessory: View>: View {
    let title: String
    let count: Int
    let totalCount: Int?
    let isBusy: Bool
    @ViewBuilder var accessory: Accessory

    init(title: String, count: Int, totalCount: Int? = nil, isBusy: Bool, @ViewBuilder accessory: () -> Accessory = { EmptyView() }) {
        self.title = title
        self.count = count
        self.totalCount = totalCount
        self.isBusy = isBusy
        self.accessory = accessory()
    }

    var body: some View {
        HStack {
            Text(title)
                .font(.title2.weight(.semibold))
            Text(countText)
                .foregroundStyle(.secondary)
            Spacer()
            accessory
            if isBusy {
                ProgressView()
                    .controlSize(.small)
            }
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 12)
        .background(.bar)
    }

    private var countText: String {
        guard let totalCount, totalCount != count else {
            return "\(count)"
        }
        return "\(count) of \(totalCount)"
    }
}

struct HomebrewPackageActionBar: View {
    let package: BrewPackage
    @Bindable var store: BrewStore

    var body: some View {
        HStack(spacing: 10) {
            VStack(alignment: .leading, spacing: 2) {
                Text(package.name)
                    .font(.headline)
                Text(package.versionSummary)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            Spacer()
            Button {
                Task { await store.showInfo(for: package) }
            } label: {
                Label("Info", systemImage: "info.circle")
            }
            .disabled(store.isRunningCommand)
            Button {
                Task { await store.upgrade(package) }
            } label: {
                Label("Upgrade", systemImage: "square.and.arrow.up")
            }
            .disabled(store.isRunningCommand)
            Button(role: .destructive) {
                Task { await store.uninstall(package) }
            } label: {
                Label("Uninstall", systemImage: "trash")
            }
            .disabled(store.isRunningCommand)
        }
        .padding(12)
        .brewGlass(cornerRadius: 0)
    }
}
