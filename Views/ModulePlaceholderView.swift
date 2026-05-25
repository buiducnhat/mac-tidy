import SwiftUI

struct ModulePlaceholderView: View {
    let title: String
    let subtitle: String
    let systemImage: String
    let primaryActionTitle: String
    let primaryActionSystemImage: String

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(spacing: 12) {
                Image(systemName: systemImage)
                    .font(.system(size: 30, weight: .semibold))
                    .foregroundStyle(.tint)
                    .frame(width: 44, height: 44)

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.title2.weight(.semibold))

                    Text(subtitle)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            Divider()

            ContentUnavailableView {
                Label("No Results Yet", systemImage: systemImage)
            } description: {
                Text("Scanning and cleanup behavior will be added in the next implementation phases.")
            } actions: {
                Button {
                } label: {
                    Label(primaryActionTitle, systemImage: primaryActionSystemImage)
                }
                .disabled(true)
            }
        }
        .padding(28)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                } label: {
                    Label(primaryActionTitle, systemImage: primaryActionSystemImage)
                }
                .disabled(true)
            }
        }
    }
}
