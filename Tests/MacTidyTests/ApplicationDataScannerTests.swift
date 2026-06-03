import Foundation
import MacTidyCore

struct ApplicationDataScannerTests {
    var temporaryDirectories: [URL] = []

    mutating func run() async throws {
        defer { tearDown() }
        try await testBundleIdentifierMatchesRelatedData()
        try await testAppNameFallbackMatchesExactNamesOnly()
        try await testSymlinkRelatedDataIsSkipped()
        try await testDefaultSelectionBehavior()
    }

    mutating func testBundleIdentifierMatchesRelatedData() async throws {
        let root = try makeTemporaryDirectory()
        let app = makeApplication(root: root)
        let support = try makeLibraryRoot(named: "Application Support")
        let preferences = try makeLibraryRoot(named: "Preferences")
        let supportMatch = support.appendingPathComponent("com.example.fixture", isDirectory: true)
        try FileManager.default.createDirectory(at: supportMatch, withIntermediateDirectories: true)
        try Data([1, 2]).write(to: supportMatch.appendingPathComponent("state.db"))
        let preferencesMatch = preferences.appendingPathComponent("com.example.fixture.plist")
        try Data([3]).write(to: preferencesMatch)

        let scanner = ApplicationDataScanner(libraryRoots: [support, preferences])
        let items = try await scanner.scan(for: app)

        try expect(items.first?.kind == .appBundle, "Expected app bundle item first")
        try expect(items.contains { $0.url == supportMatch.standardizedFileURL }, "Expected bundle identifier support match")
        try expect(items.contains { $0.url == preferencesMatch.standardizedFileURL }, "Expected bundle identifier preferences match")
    }

    mutating func testAppNameFallbackMatchesExactNamesOnly() async throws {
        let root = try makeTemporaryDirectory()
        let app = makeApplication(root: root, bundleIdentifier: nil)
        let logs = try makeLibraryRoot(named: "Logs")
        let exact = logs.appendingPathComponent("Fixture", isDirectory: true)
        let suffix = logs.appendingPathComponent("Fixture.savedState", isDirectory: true)
        let falsePositive = logs.appendingPathComponent("FixtureHelper", isDirectory: true)
        try FileManager.default.createDirectory(at: exact, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: suffix, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: falsePositive, withIntermediateDirectories: true)

        let scanner = ApplicationDataScanner(libraryRoots: [logs])
        let items = try await scanner.scan(for: app)

        try expect(items.contains { $0.url == exact.standardizedFileURL }, "Expected exact app-name match")
        try expect(items.contains { $0.url == suffix.standardizedFileURL }, "Expected app-name suffix match")
        try expect(!items.contains { $0.url == falsePositive.standardizedFileURL }, "Expected app-name false positive to be avoided")
    }

    mutating func testSymlinkRelatedDataIsSkipped() async throws {
        let root = try makeTemporaryDirectory()
        let app = makeApplication(root: root)
        let caches = try makeLibraryRoot(named: "Caches")
        let target = root.appendingPathComponent("target", isDirectory: true)
        try FileManager.default.createDirectory(at: target, withIntermediateDirectories: true)
        let link = caches.appendingPathComponent("com.example.fixture", isDirectory: true)
        try FileManager.default.createSymbolicLink(at: link, withDestinationURL: target)

        let scanner = ApplicationDataScanner(libraryRoots: [caches])
        let items = try await scanner.scan(for: app)

        try expect(!items.contains { $0.url == link.standardizedFileURL }, "Expected symlink related data to be skipped")
    }

    mutating func testDefaultSelectionBehavior() async throws {
        let root = try makeTemporaryDirectory()
        let app = makeApplication(root: root)
        let support = try makeLibraryRoot(named: "Application Support")
        let supportMatch = support.appendingPathComponent("com.example.fixture", isDirectory: true)
        try FileManager.default.createDirectory(at: supportMatch, withIntermediateDirectories: true)

        let scanner = ApplicationDataScanner(libraryRoots: [support])
        let items = try await scanner.scan(for: app)

        let appItem = try require(items.first { $0.kind == .appBundle }, "Expected app bundle item")
        let relatedItem = try require(items.first { $0.kind == .relatedData }, "Expected related data item")
        try expect(appItem.isSelectedByDefault, "Expected app bundle to be selected by default")
        try expect(!relatedItem.isSelectedByDefault, "Expected related data to be unselected by default")
        try expect(relatedItem.cleanupPolicy == .reviewRequired, "Expected related data to require review")
    }

    private func makeApplication(
        root: URL,
        displayName: String = "Fixture",
        bundleIdentifier: String? = "com.example.fixture"
    ) -> InstalledApplication {
        let appURL = root.appendingPathComponent("\(displayName).app", isDirectory: true)
        return InstalledApplication(
            url: appURL,
            displayName: displayName,
            bundleIdentifier: bundleIdentifier,
            version: "1.0",
            size: 10,
            lastModified: nil,
            sourceRoot: root,
            isUninstallable: true
        )
    }

    private mutating func makeLibraryRoot(named name: String) throws -> URL {
        let root = try makeTemporaryDirectory().appendingPathComponent(name, isDirectory: true)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        return root
    }

    private mutating func makeTemporaryDirectory() throws -> URL {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        temporaryDirectories.append(url)
        return url
    }

    private func tearDown() {
        for url in temporaryDirectories {
            try? FileManager.default.removeItem(at: url)
        }
    }
}
