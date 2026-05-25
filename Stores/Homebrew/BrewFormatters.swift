import Foundation

@MainActor
enum BrewFormatters {
    static let duration: MeasurementFormatter = {
        let formatter = MeasurementFormatter()
        formatter.unitOptions = .providedUnit
        formatter.numberFormatter.maximumFractionDigits = 1
        return formatter
    }()

    static let timestamp: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .medium
        return formatter
    }()

    static let packageDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }()

    static let byteCount: ByteCountFormatter = {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB, .useGB]
        formatter.countStyle = .file
        formatter.includesUnit = true
        return formatter
    }()

    static func formatDuration(_ interval: TimeInterval) -> String {
        duration.string(from: Measurement(value: interval, unit: UnitDuration.seconds))
    }

    static func formatPackageDate(_ date: Date?) -> String {
        guard let date else { return "—" }
        return packageDate.string(from: date)
    }

    static func formatPackageSize(_ bytes: Int64?) -> String {
        guard let bytes, bytes > 0 else { return "—" }
        return byteCount.string(fromByteCount: bytes)
    }
}
