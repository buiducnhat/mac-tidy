import Foundation
import MacTidyCore

struct FullDiskAccessServiceTests {
    func run() throws {
        try testStatusIsGrantedWhenProtectedLocationIsReadable()
        try testStatusIsDeniedWhenProtectedLocationExistsButIsUnreadable()
        try testStatusIsUndeterminedWhenNoProtectedLocationExists()
        try testOpenPrivacySettingsUsesFullDiskAccessURL()
    }

    func testStatusIsGrantedWhenProtectedLocationIsReadable() throws {
        let protectedURL = URL(fileURLWithPath: "/protected/TCC.db")
        let service = FullDiskAccessService(
            protectedLocations: { [protectedURL] },
            urlExists: { _ in true },
            canReadURL: { _ in true },
            openURL: { _ in false }
        )

        try expect(service.status() == .granted, "Expected readable protected location to grant Full Disk Access")
    }

    func testStatusIsDeniedWhenProtectedLocationExistsButIsUnreadable() throws {
        let protectedURL = URL(fileURLWithPath: "/protected/TCC.db")
        let service = FullDiskAccessService(
            protectedLocations: { [protectedURL] },
            urlExists: { _ in true },
            canReadURL: { _ in false },
            openURL: { _ in false }
        )

        try expect(service.status() == .denied, "Expected unreadable protected location to deny Full Disk Access")
    }

    func testStatusIsUndeterminedWhenNoProtectedLocationExists() throws {
        let protectedURL = URL(fileURLWithPath: "/protected/TCC.db")
        let service = FullDiskAccessService(
            protectedLocations: { [protectedURL] },
            urlExists: { _ in false },
            canReadURL: { _ in false },
            openURL: { _ in false }
        )

        try expect(service.status() == .undetermined, "Expected missing protected locations to make status undetermined")
    }

    func testOpenPrivacySettingsUsesFullDiskAccessURL() throws {
        var openedURL: URL?
        let service = FullDiskAccessService(
            protectedLocations: { [] },
            urlExists: { _ in false },
            canReadURL: { _ in false },
            openURL: { url in
                openedURL = url
                return true
            }
        )

        try expect(service.openPrivacySettings(), "Expected privacy settings opener to report success")
        try expect(openedURL == FullDiskAccessService.privacySettingsURL, "Expected Full Disk Access settings URL")
    }
}
