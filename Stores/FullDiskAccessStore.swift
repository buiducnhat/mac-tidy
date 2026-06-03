import MacTidyCore
import Observation

@MainActor
@Observable
final class FullDiskAccessStore {
    var status: FullDiskAccessStatus = .undetermined
    var isRequestPresented = false

    private let service: FullDiskAccessService
    private var didCheckOnLaunch = false

    init(service: FullDiskAccessService = FullDiskAccessService()) {
        self.service = service
    }

    func requestOnLaunchIfNeeded() {
        guard !didCheckOnLaunch else { return }

        didCheckOnLaunch = true
        refreshStatus()
        isRequestPresented = status.requiresUserAction
    }

    func checkAgain() {
        refreshStatus()

        if !status.requiresUserAction {
            isRequestPresented = false
        }
    }

    func openPrivacySettings() {
        service.openPrivacySettings()
    }

    func dismissRequest() {
        isRequestPresented = false
    }

    private func refreshStatus() {
        status = service.status()
    }
}
