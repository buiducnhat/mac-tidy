import OSLog

public enum AppLog {
    public static let scan = Logger(subsystem: "dev.nhatbui.MacTidy", category: "scan")
    public static let cleanup = Logger(subsystem: "dev.nhatbui.MacTidy", category: "cleanup")
}
