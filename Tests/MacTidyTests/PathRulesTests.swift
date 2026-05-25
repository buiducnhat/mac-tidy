import Foundation
import MacTidyCore

struct PathRulesTests {
    func run() throws {
        testContainmentRequiresRootPrefixBoundary()
        try testPathDisplayAbbreviatesHome()
    }

    func testContainmentRequiresRootPrefixBoundary() {
        let root = URL(fileURLWithPath: "/Users/example/Downloads")
        let child = URL(fileURLWithPath: "/Users/example/Downloads/file.dmg")
        let sibling = URL(fileURLWithPath: "/Users/example/Downloads-old/file.dmg")

        precondition(ProtectedPathRules.isContained(child, in: root))
        precondition(!ProtectedPathRules.isContained(sibling, in: root))
    }

    func testPathDisplayAbbreviatesHome() throws {
        let home = FileManager.default.homeDirectoryForCurrentUser
        let downloads = home.appendingPathComponent("Downloads")

        try expect(PathDisplay.abbreviated(home) == "~", "Expected home path to abbreviate as ~")
        try expect(PathDisplay.abbreviated(downloads).hasPrefix("~/"), "Expected child path to abbreviate under ~")
    }
}
