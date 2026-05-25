import Foundation

public struct ScanSummary: Equatable {
    public var scannedRoots: Int
    public var itemCount: Int
    public var totalBytes: Int64
    public var diagnosticsCount: Int
    public var startedAt: Date
    public var finishedAt: Date?
    public var wasCancelled: Bool

    public init(scannedRoots: Int, itemCount: Int, totalBytes: Int64, diagnosticsCount: Int, startedAt: Date, finishedAt: Date?, wasCancelled: Bool) {
        self.scannedRoots = scannedRoots
        self.itemCount = itemCount
        self.totalBytes = totalBytes
        self.diagnosticsCount = diagnosticsCount
        self.startedAt = startedAt
        self.finishedAt = finishedAt
        self.wasCancelled = wasCancelled
    }

    public static var empty: ScanSummary {
        ScanSummary(
            scannedRoots: 0,
            itemCount: 0,
            totalBytes: 0,
            diagnosticsCount: 0,
            startedAt: Date(),
            finishedAt: nil,
            wasCancelled: false
        )
    }
}
