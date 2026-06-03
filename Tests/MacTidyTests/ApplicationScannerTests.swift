import Foundation
import MacTidyCore

struct ApplicationScannerTests {
    var temporaryDirectories: [URL] = []

    mutating func run() async throws {
        defer { tearDown() }
        try await testScansApplicationMetadataAndSize()
        try await testSymlinkApplicationsAreSkipped()
        try await testInventoryOnlyRootsAreNotUninstallable()
        try await testApplicationsAreSortedByDisplayName()
    }

    mutating func testScansApplicationMetadataAndSize() async throws {
        let root = try makeTemporaryDirectory()
        let app = try makeApplication(
            root: root,
            name: "Fixture.app",
            displayName: "Fixture",
            bundleIdentifier: "com.example.fixture",
            version: "1.2.3",
            payloadSize: 512
        )

        let scanner = InstalledApplicationScanner(roots: [root], inventoryOnlyRoots: [])
        let applications = try await scanner.scan()

        let item = try require(applications.first, "Expected one scanned application")
        let infoSize = try fileSize(app.appendingPathComponent("Contents/Info.plist"))
        let payloadSize = try fileSize(app.appendingPathComponent("Contents/payload.dat"))
        try expect(item.url == app.standardizedFileURL, "Expected app URL to match fixture")
        try expect(item.displayName == "Fixture", "Expected display name from Info.plist")
        try expect(item.bundleIdentifier == "com.example.fixture", "Expected bundle identifier from Info.plist")
        try expect(item.version == "1.2.3", "Expected version from Info.plist")
        try expect(item.size == infoSize + payloadSize, "Expected size to count bundle files")
        try expect(item.isUninstallable, "Expected normal app root to be uninstallable")
    }

    mutating func testSymlinkApplicationsAreSkipped() async throws {
        let root = try makeTemporaryDirectory()
        let targetRoot = try makeTemporaryDirectory()
        let target = try makeApplication(root: targetRoot, name: "Target.app", displayName: "Target")
        let link = root.appendingPathComponent("Linked.app", isDirectory: true)
        try FileManager.default.createSymbolicLink(at: link, withDestinationURL: target)

        let scanner = InstalledApplicationScanner(roots: [root], inventoryOnlyRoots: [])
        let applications = try await scanner.scan()

        try expect(applications.isEmpty, "Expected symlinked app bundle to be skipped")
    }

    mutating func testInventoryOnlyRootsAreNotUninstallable() async throws {
        let root = try makeTemporaryDirectory()
        try makeApplication(root: root, name: "SystemFixture.app", displayName: "System Fixture")

        let scanner = InstalledApplicationScanner(roots: [root], inventoryOnlyRoots: [root])
        let applications = try await scanner.scan()

        let item = try require(applications.first, "Expected inventory app to be visible")
        try expect(!item.isUninstallable, "Expected inventory-only root app to be non-uninstallable")
    }

    mutating func testApplicationsAreSortedByDisplayName() async throws {
        let root = try makeTemporaryDirectory()
        try makeApplication(root: root, name: "Zeta.app", displayName: "Zeta")
        try makeApplication(root: root, name: "Alpha.app", displayName: "Alpha")

        let scanner = InstalledApplicationScanner(roots: [root], inventoryOnlyRoots: [])
        let applications = try await scanner.scan()

        try expect(applications.map(\.displayName) == ["Alpha", "Zeta"], "Expected applications to sort by display name")
    }

    @discardableResult
    private mutating func makeApplication(
        root: URL,
        name: String,
        displayName: String,
        bundleIdentifier: String = "com.example.app",
        version: String = "1.0",
        payloadSize: Int = 1
    ) throws -> URL {
        let app = root.appendingPathComponent(name, isDirectory: true)
        let contents = app.appendingPathComponent("Contents", isDirectory: true)
        try FileManager.default.createDirectory(at: contents, withIntermediateDirectories: true)

        let info: [String: Any] = [
            "CFBundleDisplayName": displayName,
            "CFBundleIdentifier": bundleIdentifier,
            "CFBundleShortVersionString": version
        ]
        let data = try PropertyListSerialization.data(fromPropertyList: info, format: .xml, options: 0)
        try data.write(to: contents.appendingPathComponent("Info.plist"))
        try Data(repeating: 7, count: payloadSize).write(to: contents.appendingPathComponent("payload.dat"))

        return app
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

    private func fileSize(_ url: URL) throws -> Int64 {
        let values = try url.resourceValues(forKeys: [.fileSizeKey])
        return Int64(values.fileSize ?? 0)
    }
}
