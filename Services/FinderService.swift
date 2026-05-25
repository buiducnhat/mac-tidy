import AppKit
import Foundation

public struct FinderService {
    public init() {}

    public func reveal(_ url: URL) {
        NSWorkspace.shared.activateFileViewerSelecting([url.standardizedFileURL])
    }
}
