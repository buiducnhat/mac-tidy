import MacTidyCore
import SwiftUI

struct SidebarView: View {
    @Binding var selection: SidebarDestination
    @State private var isHomebrewExpanded = true

    var body: some View {
        List(selection: $selection) {
            Section("MacTidy") {
                ForEach(SidebarDestination.macTidyDestinations) { destination in
                    SidebarRow(destination: destination)
                        .tag(destination)
                }
            }

            SidebarDisclosureRow(
                destination: .homebrew,
                isExpanded: $isHomebrewExpanded
            )
            .tag(SidebarDestination.homebrew)

            if isHomebrewExpanded {
                ForEach(SidebarDestination.homebrewDestinations) { destination in
                    SidebarRow(destination: destination, reservesDisclosureColumn: true)
                        .tag(destination)
                }
            }
        }
        .listStyle(.sidebar)
        .navigationTitle("MacTidy")
        .toolbar {
            SettingsLink {
                Label("Settings", systemImage: "gearshape")
            }
        }
    }
}

private struct SidebarRow: View {
    let destination: SidebarDestination
    var reservesDisclosureColumn = false

    var body: some View {
        HStack(spacing: 10) {
            if reservesDisclosureColumn {
                Color.clear
                    .frame(width: 14)
            }

            Image(systemName: destination.systemImage)
                .foregroundStyle(.secondary)
                .frame(width: 20)

            VStack(alignment: .leading, spacing: 2) {
                Text(destination.title)
                    .lineLimit(1)

                Text(destination.detail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
    }
}

private struct SidebarDisclosureRow: View {
    let destination: SidebarDestination
    @Binding var isExpanded: Bool

    var body: some View {
        HStack(spacing: 10) {
            Button {
                isExpanded.toggle()
            } label: {
                Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .frame(width: 14)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            Image(systemName: destination.systemImage)
                .foregroundStyle(.secondary)
                .frame(width: 20)

            VStack(alignment: .leading, spacing: 2) {
                Text(destination.title)
                    .lineLimit(1)

                Text(destination.detail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
    }
}
