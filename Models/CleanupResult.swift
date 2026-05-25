import Foundation

public struct CleanupResult: Identifiable, Hashable {
    public enum Status: Hashable {
        case movedToTrash
        case refused
        case failed
    }

    public let id = UUID()
    public let url: URL
    public let status: Status
    public let message: String

    public init(url: URL, status: Status, message: String) {
        self.url = url.standardizedFileURL
        self.status = status
        self.message = message
    }
}
