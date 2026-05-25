import Foundation

public enum SidebarDestination: String, CaseIterable, Identifiable {
    case dashboard
    case analyze
    case clean
    case purge
    case installers
    case homebrew
    case homebrewDashboard
    case homebrewInstalled
    case homebrewOutdated
    case homebrewSearch
    case homebrewTaps
    case homebrewUtilities

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .dashboard: "Dashboard"
        case .analyze: "Analyze"
        case .clean: "Clean"
        case .purge: "Purge"
        case .installers: "Installers"
        case .homebrew: "Homebrew"
        case .homebrewDashboard: "Overview"
        case .homebrewInstalled: "Installed"
        case .homebrewOutdated: "Outdated"
        case .homebrewSearch: "Search"
        case .homebrewTaps: "Taps"
        case .homebrewUtilities: "Utilities"
        }
    }

    public var detail: String {
        switch self {
        case .dashboard: "Overview"
        case .analyze: "Disk review"
        case .clean: "Caches"
        case .purge: "Project artifacts"
        case .installers: "Install files"
        case .homebrew: "Packages"
        case .homebrewDashboard: "Brew status"
        case .homebrewInstalled: "Formulae and casks"
        case .homebrewOutdated: "Available upgrades"
        case .homebrewSearch: "Install packages"
        case .homebrewTaps: "Repositories"
        case .homebrewUtilities: "Maintenance"
        }
    }

    public var systemImage: String {
        switch self {
        case .dashboard: "gauge.with.dots.needle.67percent"
        case .analyze: "magnifyingglass.circle"
        case .clean: "sparkles"
        case .purge: "shippingbox"
        case .installers: "opticaldiscdrive"
        case .homebrew: "mug"
        case .homebrewDashboard: "mug"
        case .homebrewInstalled: "shippingbox"
        case .homebrewOutdated: "exclamationmark.arrow.triangle.2.circlepath"
        case .homebrewSearch: "magnifyingglass"
        case .homebrewTaps: "tray.2"
        case .homebrewUtilities: "wrench.and.screwdriver"
        }
    }

    public var isHomebrew: Bool {
        switch self {
        case .homebrew, .homebrewDashboard, .homebrewInstalled, .homebrewOutdated, .homebrewSearch, .homebrewTaps, .homebrewUtilities:
            true
        default:
            false
        }
    }

    public static let macTidyDestinations: [SidebarDestination] = [
        .dashboard,
        .analyze,
        .clean,
        .purge,
        .installers
    ]

    public static let homebrewDestinations: [SidebarDestination] = [
        .homebrewDashboard,
        .homebrewInstalled,
        .homebrewOutdated,
        .homebrewSearch,
        .homebrewTaps,
        .homebrewUtilities
    ]
}
