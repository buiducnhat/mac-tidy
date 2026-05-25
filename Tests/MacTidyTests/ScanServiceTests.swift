import Foundation
import MacTidyCore

struct ScanServiceTests {
    var temporaryDirectories: [URL] = []

    mutating func run() async throws {
        defer { tearDown() }
        try await testScanReportsTopLevelDirectorySize()
        testProtectedPathsAreBlocked()
        try await testSymlinkTopLevelItemsAreSkipped()
        try await testUnreadableOrDisallowedRootProducesDiagnostic()
    }

    mutating func testScanReportsTopLevelDirectorySize() async throws {
        let root = try makeTemporaryDirectory()
        let folder = root.appendingPathComponent("Project", isDirectory: true)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        try Data(repeating: 1, count: 1024).write(to: folder.appendingPathComponent("artifact.bin"))

        let service = ScanService(maxItemsPerRoot: 20)
        let result = try await service.scan(roots: [ScanRoot(title: "Fixture", url: root)])

        let item = try require(result.items.first { $0.name == "Project" }, "Expected Project scan item")
        try expect(item.size == 1024, "Expected Project size to be 1024 bytes")
        try expect(item.category == .folder, "Expected Project to be categorized as folder")
        try expect(item.cleanupPolicy == .scanOnly, "Expected Analyze items to be scan-only")
    }

    func testProtectedPathsAreBlocked() {
        precondition(ProtectedPathRules.isProtected(URL(fileURLWithPath: "/System/Library")))
        precondition(ProtectedPathRules.isProtected(URL(fileURLWithPath: "/usr/bin/swift")))
        precondition(!ProtectedPathRules.isProtected(FileManager.default.homeDirectoryForCurrentUser))
    }

    mutating func testSymlinkTopLevelItemsAreSkipped() async throws {
        let root = try makeTemporaryDirectory()
        let target = root.appendingPathComponent("target.txt")
        let link = root.appendingPathComponent("linked.txt")
        try Data(repeating: 2, count: 128).write(to: target)
        try FileManager.default.createSymbolicLink(at: link, withDestinationURL: target)

        let service = ScanService(maxItemsPerRoot: 20)
        let result = try await service.scan(roots: [ScanRoot(title: "Fixture", url: root)])

        try expect(result.items.contains { $0.name == "target.txt" }, "Expected real target file in scan results")
        try expect(!result.items.contains { $0.name == "linked.txt" }, "Expected symlink to be skipped")
    }

    func testUnreadableOrDisallowedRootProducesDiagnostic() async throws {
        let root = URL(fileURLWithPath: "/System")
        let service = ScanService(maxItemsPerRoot: 20)
        let result = try await service.scan(roots: [ScanRoot(title: "System", url: root)])

        try expect(result.items.isEmpty, "Expected protected root to produce no scan items")
        try expect(result.diagnostics.count == 1, "Expected one diagnostic for protected root")
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
