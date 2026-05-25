import MacTidyCore
import SwiftUI

struct HomebrewDashboardView: View {
    @Bindable var store: BrewStore
    var navigate: (SidebarDestination, BrewPackageFilter?) -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                HomebrewHeaderView(
                    title: "Homebrew Overview",
                    subtitle: store.brewPath,
                    isBusy: store.isLoading || store.isRunningCommand
                )

                LazyVGrid(columns: [GridItem(.adaptive(minimum: 190), spacing: 12)], spacing: 12) {
                    HomebrewMetricCard(title: "Formulae", value: "\(store.formulaCount)", systemImage: "terminal") {
                        navigate(.homebrewInstalled, .formulae)
                    }
                    HomebrewMetricCard(title: "Casks", value: "\(store.caskCount)", systemImage: "macwindow") {
                        navigate(.homebrewInstalled, .casks)
                    }
                    HomebrewMetricCard(title: "Outdated", value: "\(store.outdatedPackages.count)", systemImage: "exclamationmark.arrow.triangle.2.circlepath") {
                        navigate(.homebrewOutdated, nil)
                    }
                    HomebrewMetricCard(title: "Taps", value: "\(store.taps.count)", systemImage: "tray.2") {
                        navigate(.homebrewTaps, nil)
                    }
                }

                HomebrewSectionBox(title: "Next Actions") {
                    HStack(spacing: 10) {
                        HomebrewUtilityButton(utility: .doctor, store: store)
                        HomebrewUtilityButton(utility: .cleanupDryRun, store: store)
                        HomebrewUtilityButton(utility: .upgradeAll, store: store)
                    }
                }

                HomebrewCommandOutputView(result: store.activeResult, history: store.commandHistory)
            }
            .padding(24)
        }
    }
}

struct HomebrewHeaderView: View {
    let title: String
    let subtitle: String
    let isBusy: Bool

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.largeTitle.weight(.semibold))
                Text(subtitle)
                    .foregroundStyle(.secondary)
                    .textSelection(.enabled)
            }
            Spacer()
            if isBusy {
                ProgressView()
                    .controlSize(.small)
            }
        }
    }
}

struct HomebrewMetricCard: View {
    let title: String
    let value: String
    let systemImage: String
    let action: (() -> Void)?

    init(title: String, value: String, systemImage: String, action: (() -> Void)? = nil) {
        self.title = title
        self.value = value
        self.systemImage = systemImage
        self.action = action
    }

    var body: some View {
        Group {
            if let action {
                Button(action: action) {
                    cardContent
                }
                .buttonStyle(.plain)
            } else {
                cardContent
            }
        }
    }

    private var cardContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: systemImage)
                    .foregroundStyle(.secondary)
                Spacer()
                if action != nil {
                    Image(systemName: "arrow.up.right")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.tertiary)
                }
            }
            Text(value)
                .font(.system(size: 34, weight: .semibold, design: .rounded))
            Text(title)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .brewGlass(cornerRadius: 14, interactive: action != nil)
    }
}

struct HomebrewSectionBox<Content: View>: View {
    let title: String
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
            content
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .brewGlass(cornerRadius: 14)
    }
}
