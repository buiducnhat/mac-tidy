import Foundation

enum BrewClientError: LocalizedError {
    case brewNotFound

    var errorDescription: String? {
        switch self {
        case .brewNotFound:
            "Could not find the brew executable. Install Homebrew or set a supported path."
        }
    }
}

struct BrewClient: Sendable {
    var executableURL: URL?

    init(executableURL: URL? = BrewClient.locateBrew()) {
        self.executableURL = executableURL
    }

    var isAvailable: Bool {
        executableURL != nil
    }

    var displayPath: String {
        executableURL?.path ?? "Not found"
    }

    func run(_ arguments: [String]) async throws -> BrewCommandResult {
        guard let executableURL else {
            throw BrewClientError.brewNotFound
        }

        let command = ([executableURL.path] + arguments).joined(separator: " ")
        let started = Date()

        return try await Task.detached(priority: .userInitiated) {
            let process = Process()
            let outputPipe = Pipe()
            let errorPipe = Pipe()

            process.executableURL = executableURL
            process.arguments = arguments
            process.standardOutput = outputPipe
            process.standardError = errorPipe
            process.environment = ProcessInfo.processInfo.environment.merging([
                "HOMEBREW_NO_ENV_HINTS": "1",
                "HOMEBREW_NO_AUTO_UPDATE": "1"
            ]) { current, _ in current }

            try process.run()
            process.waitUntilExit()

            let stdout = String(data: outputPipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
            let stderr = String(data: errorPipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
            let mergedOutput = [stdout, stderr]
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }
                .joined(separator: "\n")

            return BrewCommandResult(
                command: command,
                exitCode: process.terminationStatus,
                output: mergedOutput,
                startedAt: started,
                finishedAt: Date()
            )
        }.value
    }

    func installedFormulae() async throws -> [BrewPackage] {
        let result = try await run(["list", "--formula", "--versions"])
        return await enrichedPackages(from: parseVersionList(result.output, kind: .formula))
    }

    func installedCasks() async throws -> [BrewPackage] {
        let result = try await run(["list", "--cask", "--versions"])
        return await enrichedPackages(from: parseVersionList(result.output, kind: .cask))
    }

    func outdated() async throws -> [BrewPackage] {
        let result = try await run(["outdated", "--verbose"])
        return await enrichedPackages(from: parseOutdated(result.output))
    }

    func taps() async throws -> [BrewTap] {
        let result = try await run(["tap"])
        return result.output
            .split(whereSeparator: \.isNewline)
            .map { BrewTap(name: String($0)) }
            .sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
    }

    func search(_ term: String) async throws -> [BrewPackage] {
        let cleanTerm = term.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanTerm.isEmpty else { return [] }

        let result = try await run(["search", cleanTerm])
        return parseSearch(result.output)
    }

    func info(for package: BrewPackage) async throws -> BrewCommandResult {
        let flag = package.kind == .cask ? "--cask" : "--formula"
        return try await run(["info", flag, package.name])
    }

    func packageInfo(for package: BrewPackage) async throws -> BrewPackageInfo {
        let result = try await info(for: package)
        return parsePackageInfo(package: package, result: result)
    }

    static func locateBrew() -> URL? {
        let candidates = [
            "/opt/homebrew/bin/brew",
            "/usr/local/bin/brew",
            "/home/linuxbrew/.linuxbrew/bin/brew"
        ]

        if let path = candidates.first(where: { FileManager.default.isExecutableFile(atPath: $0) }) {
            return URL(fileURLWithPath: path)
        }

        let pathEnvironment = ProcessInfo.processInfo.environment["PATH"] ?? ""
        for directory in pathEnvironment.split(separator: ":") {
            let path = "\(directory)/brew"
            if FileManager.default.isExecutableFile(atPath: path) {
                return URL(fileURLWithPath: path)
            }
        }

        return nil
    }

    private func parseVersionList(_ output: String, kind: BrewPackageKind) -> [BrewPackage] {
        output
            .split(whereSeparator: \.isNewline)
            .compactMap { line -> BrewPackage? in
                let parts = line.split(separator: " ", omittingEmptySubsequences: true).map(String.init)
                guard let name = parts.first else { return nil }
                let versions = parts.dropFirst().joined(separator: ", ")
                return BrewPackage(
                    name: name,
                    kind: kind,
                    installedVersion: versions.isEmpty ? nil : versions,
                    currentVersion: nil,
                    description: nil
                )
            }
            .sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
    }

    private func enrichedPackages(from packages: [BrewPackage]) async -> [BrewPackage] {
        let executableURL = executableURL
        return await Task.detached(priority: .utility) {
            let resolver = BrewPackageMetadataResolver(brewExecutableURL: executableURL)
            return packages.map(resolver.enriched)
        }.value
    }

    private func parseOutdated(_ output: String) -> [BrewPackage] {
        output
            .split(whereSeparator: \.isNewline)
            .compactMap { line -> BrewPackage? in
                let text = String(line)
                guard let opening = text.firstIndex(of: "("),
                      let closing = text.firstIndex(of: ")") else {
                    let name = text.split(separator: " ").first.map(String.init)
                    return name.map { BrewPackage(name: $0, kind: .formula, installedVersion: nil, currentVersion: nil, description: nil) }
                }

                let name = String(text[..<opening]).trimmingCharacters(in: .whitespaces)
                let versions = text[text.index(after: opening)..<closing]
                    .split(separator: "<")
                    .map { $0.trimmingCharacters(in: .whitespaces) }

                return BrewPackage(
                    name: name,
                    kind: text.contains("(cask)") ? .cask : .formula,
                    installedVersion: versions.first,
                    currentVersion: versions.dropFirst().first,
                    description: nil
                )
            }
            .sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
    }

    private func parseSearch(_ output: String) -> [BrewPackage] {
        var currentKind: BrewPackageKind = .formula
        var packages: [BrewPackage] = []

        for rawLine in output.split(whereSeparator: \.isNewline).map(String.init) {
            let line = rawLine.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !line.isEmpty else { continue }

            if line.localizedCaseInsensitiveContains("formulae") {
                currentKind = .formula
                continue
            }

            if line.localizedCaseInsensitiveContains("casks") {
                currentKind = .cask
                continue
            }

            line
                .split(separator: " ", omittingEmptySubsequences: true)
                .map(String.init)
                .forEach { name in
                    packages.append(BrewPackage(name: name, kind: currentKind, installedVersion: nil, currentVersion: nil, description: nil))
                }
        }

        return packages.sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
    }

    private func parsePackageInfo(package: BrewPackage, result: BrewCommandResult) -> BrewPackageInfo {
        let lines = result.output
            .split(whereSeparator: \.isNewline)
            .map(String.init)

        var headline = package.name
        var descriptionLines: [String] = []
        var homepage: URL?
        var statusLines: [String] = []
        var sections: [BrewInfoSection] = []
        var currentTitle: String?
        var currentBody: [String] = []
        var didReadSummary = false

        func flushSection() {
            guard let currentTitle else { return }
            let body = currentBody
                .map { $0.trimmingCharacters(in: .whitespaces) }
                .filter { !$0.isEmpty }
                .joined(separator: "\n")
            if !body.isEmpty {
                sections.append(BrewInfoSection(title: currentTitle, body: body))
            }
            currentBody = []
        }

        for rawLine in lines {
            let line = rawLine.trimmingCharacters(in: .whitespaces)
            guard !line.isEmpty else { continue }

            if line.hasPrefix("==> ") {
                flushSection()
                let title = String(line.dropFirst(4))
                if !didReadSummary {
                    headline = title
                    didReadSummary = true
                    currentTitle = nil
                } else {
                    currentTitle = title
                }
                continue
            }

            if currentTitle != nil {
                currentBody.append(line)
            } else if line.hasPrefix("http"), homepage == nil {
                homepage = URL(string: line)
            } else if descriptionLines.isEmpty {
                descriptionLines.append(line)
            } else {
                statusLines.append(line)
            }
        }

        flushSection()

        return BrewPackageInfo(
            package: package,
            headline: headline,
            description: descriptionLines.isEmpty ? nil : descriptionLines.joined(separator: " "),
            homepage: homepage,
            status: statusLines.isEmpty ? nil : statusLines.joined(separator: "\n"),
            sections: sections,
            command: result.command
        )
    }
}
