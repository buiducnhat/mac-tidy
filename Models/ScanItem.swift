import Foundation

public struct ScanItem: Identifiable, Hashable {
    public let id: String
    public let url: URL
    public let name: String
    public let size: Int64
    public let lastModified: Date?
    public let category: ScanCategory
    public let risk: RiskLevel
    public let cleanupPolicy: CleanupPolicy
    public let diagnostics: [ScanDiagnostic]

    public init(
        url: URL,
        size: Int64,
        lastModified: Date?,
        category: ScanCategory,
        risk: RiskLevel,
        cleanupPolicy: CleanupPolicy,
        diagnostics: [ScanDiagnostic] = []
    ) {
        let standardizedURL = url.standardizedFileURL
        self.id = standardizedURL.path
        self.url = standardizedURL
        self.name = standardizedURL.lastPathComponent.isEmpty ? standardizedURL.path : standardizedURL.lastPathComponent
        self.size = size
        self.lastModified = lastModified
        self.category = category
        self.risk = risk
        self.cleanupPolicy = cleanupPolicy
        self.diagnostics = diagnostics
    }
}
