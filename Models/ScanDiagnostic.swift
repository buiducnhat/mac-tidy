import Foundation

public struct ScanDiagnostic: Identifiable, Hashable {
    public let id = UUID()
    public let path: String
    public let message: String

    public init(path: String, message: String) {
        self.path = path
        self.message = message
    }
}
