import Foundation

public struct ScanRoot: Identifiable, Hashable {
    public let id: String
    public let title: String
    public let url: URL
    public let isDefault: Bool

    public init(title: String, url: URL, isDefault: Bool = true) {
        self.id = url.standardizedFileURL.path
        self.title = title
        self.url = url.standardizedFileURL
        self.isDefault = isDefault
    }
}
