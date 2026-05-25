import Foundation

public struct PermissionDiagnosticsService {
    public init() {}

    public func diagnostic(for url: URL, message: String? = nil) -> ScanDiagnostic {
        ScanDiagnostic(
            path: url.standardizedFileURL.path,
            message: message ?? "MacTidy could not read this path. Choose a different folder or adjust macOS privacy permissions."
        )
    }
}
