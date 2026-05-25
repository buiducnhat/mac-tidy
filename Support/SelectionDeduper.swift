import Foundation

public enum SelectionDeduper {
    public static func collapse(_ urls: [URL]) -> [URL] {
        let sorted = urls
            .map(\.standardizedFileURL)
            .sorted { $0.path.count < $1.path.count }

        var collapsed: [URL] = []
        for url in sorted {
            if collapsed.contains(where: { ProtectedPathRules.isContained(url, in: $0) && url.path != $0.path }) {
                continue
            }
            collapsed.append(url)
        }
        return collapsed
    }
}
