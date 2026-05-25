import CoreServices
import Foundation

struct BrewPackageMetadataResolver {
    let brewExecutableURL: URL?

    func enriched(_ package: BrewPackage) -> BrewPackage {
        var package = package

        switch package.kind {
        case .cask:
            let location = caskLocation(for: package.name)
            let resolvedAppURL = location.appURL?.resolvingSymlinksInPath()
            package.displayName = resolvedAppURL.flatMap(displayName)
            package.installedAt = resourceDate(for: location.installURL ?? resolvedAppURL)
            package.lastUsedAt = resolvedAppURL.flatMap(lastUsedDate)
            package.sizeBytes = resolvedAppURL.flatMap(directorySize)
        case .formula:
            guard let formulaURL = formulaInstallURL(for: package) else { break }
            package.installedAt = resourceDate(for: formulaURL)
            package.sizeBytes = directorySize(for: formulaURL)
        }

        return package
    }

    private func caskLocation(for caskName: String) -> (appURL: URL?, installURL: URL?) {
        for root in brewRoots {
            let caskURL = root.appendingPathComponent("Caskroom", isDirectory: true)
                .appendingPathComponent(caskName, isDirectory: true)
            guard let versionURLs = directoryContents(caskURL) else { continue }

            for versionURL in versionURLs.sorted(by: newestFirst) {
                if let appURL = firstApp(in: versionURL) {
                    return (appURL, versionURL)
                }
            }
        }

        return (applicationsAppURL(for: caskName), nil)
    }

    private func formulaInstallURL(for package: BrewPackage) -> URL? {
        for root in brewRoots {
            let formulaURL = root.appendingPathComponent("Cellar", isDirectory: true)
                .appendingPathComponent(package.name, isDirectory: true)
            guard let versionURLs = directoryContents(formulaURL) else { continue }

            if let installedVersion = package.installedVersion?.split(separator: ",").first.map({ String($0).trimmingCharacters(in: .whitespaces) }) {
                let versionURL = formulaURL.appendingPathComponent(installedVersion, isDirectory: true)
                if FileManager.default.fileExists(atPath: versionURL.path) {
                    return versionURL
                }
            }

            return versionURLs.sorted(by: newestFirst).first
        }

        return nil
    }

    private var brewRoots: [URL] {
        var roots: [URL] = []
        if let brewExecutableURL {
            roots.append(brewExecutableURL.deletingLastPathComponent().deletingLastPathComponent())
        }
        roots.append(contentsOf: [
            URL(fileURLWithPath: "/opt/homebrew", isDirectory: true),
            URL(fileURLWithPath: "/usr/local", isDirectory: true)
        ])

        var seen: Set<String> = []
        return roots.filter { seen.insert($0.path).inserted }
    }

    private func applicationsAppURL(for caskName: String) -> URL? {
        let lookupKeys = [
            caskName,
            caskName.replacingOccurrences(of: "-", with: " "),
            caskName.replacingOccurrences(of: "_", with: " ")
        ].map(normalizedName)

        let directories = [
            URL(fileURLWithPath: "/Applications", isDirectory: true),
            FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Applications", isDirectory: true),
            URL(fileURLWithPath: "/Applications/Utilities", isDirectory: true)
        ]

        for directory in directories {
            guard let appURLs = directoryContents(directory) else { continue }
            for appURL in appURLs where appURL.pathExtension == "app" {
                let appName = appURL.deletingPathExtension().lastPathComponent
                if lookupKeys.contains(normalizedName(appName)) {
                    return appURL
                }
            }
        }

        return nil
    }

    private func firstApp(in directory: URL) -> URL? {
        directoryContents(directory)?.first { $0.pathExtension == "app" }
    }

    private func directoryContents(_ url: URL) -> [URL]? {
        try? FileManager.default.contentsOfDirectory(
            at: url,
            includingPropertiesForKeys: [.creationDateKey, .contentModificationDateKey],
            options: [.skipsHiddenFiles]
        )
    }

    private func displayName(for appURL: URL) -> String? {
        if let bundle = Bundle(url: appURL),
           let bundleName = (bundle.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String)
            ?? (bundle.object(forInfoDictionaryKey: "CFBundleName") as? String),
           !bundleName.isEmpty {
            return bundleName
        }

        return appURL.deletingPathExtension().lastPathComponent
    }

    private func lastUsedDate(for appURL: URL) -> Date? {
        guard let item = MDItemCreateWithURL(nil, appURL as CFURL),
              let value = MDItemCopyAttribute(item, kMDItemLastUsedDate) else {
            return nil
        }

        return value as? Date
    }

    private func resourceDate(for url: URL?) -> Date? {
        guard let url else { return nil }
        let values = try? url.resourceValues(forKeys: [.creationDateKey, .contentModificationDateKey])
        return values?.creationDate ?? values?.contentModificationDate
    }

    private func directorySize(for url: URL) -> Int64 {
        let keys: [URLResourceKey] = [.isRegularFileKey, .totalFileAllocatedSizeKey, .fileAllocatedSizeKey]
        guard let enumerator = FileManager.default.enumerator(
            at: url,
            includingPropertiesForKeys: keys,
            options: [.skipsHiddenFiles]
        ) else {
            return 0
        }

        return enumerator.compactMap { item -> Int64? in
            guard let fileURL = item as? URL,
                  let values = try? fileURL.resourceValues(forKeys: Set(keys)),
                  values.isRegularFile == true else {
                return nil
            }

            return Int64(values.totalFileAllocatedSize ?? values.fileAllocatedSize ?? 0)
        }
        .reduce(0, +)
    }

    private func newestFirst(_ lhs: URL, _ rhs: URL) -> Bool {
        let lhsDate = resourceDate(for: lhs) ?? .distantPast
        let rhsDate = resourceDate(for: rhs) ?? .distantPast
        return lhsDate > rhsDate
    }

    private func normalizedName(_ name: String) -> String {
        name
            .lowercased()
            .filter { $0.isLetter || $0.isNumber }
    }
}
