import MacTidyCore
import SwiftUI

struct FullDiskAccessRequestView: View {
    @Bindable var store: FullDiskAccessStore

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .top, spacing: 14) {
                Image(systemName: "externaldrive.badge.checkmark")
                    .font(.system(size: 34))
                    .foregroundStyle(.blue)
                    .frame(width: 42)

                VStack(alignment: .leading, spacing: 6) {
                    Text("Allow Full Disk Access")
                        .font(.title2)
                        .fontWeight(.semibold)

                    Text("MacTidy needs Full Disk Access to inspect protected app data and produce complete cleanup results.")
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            Label(statusMessage, systemImage: statusSystemImage)
                .font(.callout)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            Text("After enabling MacTidy in System Settings, return here and check again.")
                .font(.callout)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            HStack {
                Button("Later") {
                    store.dismissRequest()
                }

                Spacer()

                Button("Check Again") {
                    store.checkAgain()
                }

                Button("Open System Settings") {
                    store.openPrivacySettings()
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding(24)
        .frame(width: 480)
    }

    private var statusMessage: String {
        switch store.status {
        case .granted:
            "Full Disk Access is enabled."
        case .denied:
            "Full Disk Access is not enabled for MacTidy."
        case .undetermined:
            "MacTidy could not confirm Full Disk Access yet."
        }
    }

    private var statusSystemImage: String {
        switch store.status {
        case .granted:
            "checkmark.circle"
        case .denied:
            "exclamationmark.triangle"
        case .undetermined:
            "questionmark.circle"
        }
    }
}
