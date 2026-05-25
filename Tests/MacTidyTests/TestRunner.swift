import Foundation

@main
enum TestRunner {
    static func main() async {
        do {
            var scanServiceTests = ScanServiceTests()
            try await scanServiceTests.run()
            try PathRulesTests().run()
            try CleanupRulesTests().run()
            print("MacTidyCoreTests passed")
        } catch {
            fputs("MacTidyCoreTests failed: \(error)\n", stderr)
            Foundation.exit(1)
        }
    }
}

struct TestFailure: Error, CustomStringConvertible {
    let description: String
}

func expect(_ condition: @autoclosure () -> Bool, _ message: String) throws {
    guard condition() else {
        throw TestFailure(description: message)
    }
}

func require<T>(_ value: T?, _ message: String) throws -> T {
    guard let value else {
        throw TestFailure(description: message)
    }
    return value
}
