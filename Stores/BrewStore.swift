import Foundation
import Observation

@MainActor
@Observable
final class BrewStore {
    private(set) var installedPackages: [BrewPackage] = []
    private(set) var outdatedPackages: [BrewPackage] = []
    private(set) var taps: [BrewTap] = []
    private(set) var searchResults: [BrewPackage] = []
    private(set) var commandHistory: [BrewCommandResult] = []
    private(set) var activeResult: BrewCommandResult?
    var packageInfo: BrewPackageInfo?
    private(set) var isLoading = false
    private(set) var isRunningCommand = false
    var selectedPackageID: BrewPackage.ID?
    var installedPackageFilter: BrewPackageFilter = .all
    var outdatedPackageFilter: BrewPackageFilter = .all
    var searchTerm = ""
    var errorMessage: String?

    private let client: BrewClient

    init(client: BrewClient) {
        self.client = client
    }

    var brewPath: String {
        client.displayPath
    }

    var formulaCount: Int {
        installedPackages.filter { $0.kind == .formula }.count
    }

    var caskCount: Int {
        installedPackages.filter { $0.kind == .cask }.count
    }

    var selectedPackage: BrewPackage? {
        installedPackages.first { $0.id == selectedPackageID }
            ?? outdatedPackages.first { $0.id == selectedPackageID }
            ?? searchResults.first { $0.id == selectedPackageID }
    }

    func loadInitialData() async {
        guard installedPackages.isEmpty && outdatedPackages.isEmpty else { return }
        await refreshAll()
    }

    func refreshAll() async {
        errorMessage = nil
        isLoading = true
        defer { isLoading = false }

        do {
            async let formulae = client.installedFormulae()
            async let casks = client.installedCasks()
            async let outdated = client.outdated()
            async let loadedTaps = client.taps()

            installedPackages = try await (formulae + casks)
                .sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
            outdatedPackages = try await outdated
            taps = try await loadedTaps
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func performSearch() async {
        let term = searchTerm.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !term.isEmpty else {
            searchResults = []
            return
        }

        errorMessage = nil
        isLoading = true
        defer { isLoading = false }

        do {
            searchResults = try await client.search(term)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func installSearchResult(_ package: BrewPackage) async {
        await runPackageCommand(package.kind == .cask ? ["install", "--cask", package.name] : ["install", package.name])
    }

    func uninstall(_ package: BrewPackage) async {
        await runPackageCommand(package.kind == .cask ? ["uninstall", "--cask", package.name] : ["uninstall", package.name])
    }

    func upgrade(_ package: BrewPackage) async {
        await runPackageCommand(package.kind == .cask ? ["upgrade", "--cask", package.name] : ["upgrade", package.name])
    }

    func showInfo(for package: BrewPackage) async {
        errorMessage = nil
        isRunningCommand = true
        defer { isRunningCommand = false }

        do {
            packageInfo = try await client.packageInfo(for: package)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func runUtility(_ utility: BrewUtility) async {
        await runPackageCommand(utility.commandArguments)
    }

    func runCommand(_ arguments: [String]) async {
        await runPackageCommand(arguments)
    }

    func clearActiveResult() {
        activeResult = nil
    }

    func closePackageInfo() {
        packageInfo = nil
    }

    private func runPackageCommand(_ arguments: [String]) async {
        await runResultCommand {
            try await client.run(arguments)
        }
        await refreshAll()
    }

    private func runResultCommand(_ operation: () async throws -> BrewCommandResult) async {
        errorMessage = nil
        isRunningCommand = true
        defer { isRunningCommand = false }

        do {
            let result = try await operation()
            activeResult = result
            commandHistory.insert(result, at: 0)
            commandHistory = Array(commandHistory.prefix(20))
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
