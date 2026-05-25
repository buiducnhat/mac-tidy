import Foundation
import MacTidyCore

struct CleanupRulesTests {
    func run() throws {
        try testPurgeRuleMatchesArtifacts()
        try testInstallerRuleMatchesInstallers()
        try testSelectionDeduperCollapsesChildren()
        try testCleanupServiceRefusesProtectedAndDedupes()
        try testCleanupServiceMovesFixtureToTrash()
    }

    func testPurgeRuleMatchesArtifacts() throws {
        let url = URL(fileURLWithPath: "/tmp/App/node_modules", isDirectory: true)
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: URL(fileURLWithPath: "/tmp/App")) }

        let item = try require(PurgeRules.match(url: url), "Expected node_modules to match purge rules")
        try expect(item.category == .projectArtifact, "Expected purge artifact category")
        try expect(item.cleanupPolicy == .reviewRequired, "Expected purge artifacts to require review")
    }

    func testInstallerRuleMatchesInstallers() throws {
        let dmg = URL(fileURLWithPath: "/tmp/TestInstaller.dmg")
        FileManager.default.createFile(atPath: dmg.path, contents: Data([1]))
        defer { try? FileManager.default.removeItem(at: dmg) }

        let item = try require(InstallerRules.match(url: dmg), "Expected dmg to match installer rules")
        try expect(item.category == .installer, "Expected installer category")
        try expect(item.cleanupPolicy == .trashAllowed, "Expected common installers to be trash allowed")
    }

    func testSelectionDeduperCollapsesChildren() throws {
        let parent = URL(fileURLWithPath: "/tmp/Parent")
        let child = parent.appendingPathComponent("Child")
        let collapsed = SelectionDeduper.collapse([child, parent])

        try expect(collapsed == [parent.standardizedFileURL], "Expected child selection to collapse under selected parent")
    }

    func testCleanupServiceRefusesProtectedAndDedupes() throws {
        var trashed: [URL] = []
        let service = CleanupService { url in
            trashed.append(url)
            return url
        }
        let temp = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        let child = temp.appendingPathComponent("child")
        try FileManager.default.createDirectory(at: child, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: temp) }

        let results = service.moveToTrash(urls: [child, temp, URL(fileURLWithPath: "/System/Library")])

        try expect(trashed == [temp.standardizedFileURL], "Expected cleanup to trash only collapsed temp parent")
        try expect(results.contains { $0.status == .refused }, "Expected protected path refusal")
    }

    func testCleanupServiceMovesFixtureToTrash() throws {
        let fixture = FileManager.default.temporaryDirectory.appendingPathComponent("MacTidyTrashFixture-\(UUID().uuidString)")
        FileManager.default.createFile(atPath: fixture.path, contents: Data([1, 2, 3]))

        let results = CleanupService().moveToTrash(urls: [fixture])

        try expect(results.count == 1, "Expected one cleanup result")
        try expect(results[0].status == .movedToTrash, "Expected fixture to move to Trash")
        try expect(!FileManager.default.fileExists(atPath: fixture.path), "Expected fixture to be removed from original location")
    }
}
