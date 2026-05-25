import SwiftUI

struct HomebrewUtilitiesView: View {
    @Bindable var store: BrewStore

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                HomebrewHeaderView(
                    title: "Utilities",
                    subtitle: "Run maintenance and Brewfile workflows from Homebrew.",
                    isBusy: store.isRunningCommand
                )

                LazyVGrid(columns: [GridItem(.adaptive(minimum: 240), spacing: 12)], spacing: 12) {
                    ForEach(BrewUtility.allCases) { utility in
                        HomebrewUtilityButton(utility: utility, store: store)
                    }
                }

                HomebrewCommandOutputView(result: store.activeResult, history: store.commandHistory)
            }
            .padding(24)
        }
    }
}

struct HomebrewUtilityButton: View {
    let utility: BrewUtility
    @Bindable var store: BrewStore

    var body: some View {
        Button {
            Task { await store.runUtility(utility) }
        } label: {
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: utility.systemImage)
                    .font(.title3)
                    .foregroundStyle(Color.accentColor)
                    .frame(width: 24)
                VStack(alignment: .leading, spacing: 4) {
                    Text(utility.rawValue)
                        .font(.headline)
                    Text(utility.detail)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(3)
                }
                Spacer()
            }
            .frame(maxWidth: .infinity, minHeight: 76, alignment: .topLeading)
            .padding(12)
            .contentShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .frame(maxWidth: .infinity, minHeight: 100, alignment: .topLeading)
        .buttonStyle(.plain)
        .contentShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .brewGlass(cornerRadius: 14, interactive: true)
        .disabled(store.isRunningCommand)
    }
}

struct HomebrewCommandOutputView: View {
    let result: BrewCommandResult?
    let history: [BrewCommandResult]
    var onDismiss: (() -> Void)? = nil

    var body: some View {
        HomebrewSectionBox(title: "Command Output") {
            if let result {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Label(result.succeeded ? "Succeeded" : "Failed", systemImage: result.succeeded ? "checkmark.circle.fill" : "xmark.octagon.fill")
                            .foregroundStyle(result.succeeded ? .green : .red)
                        Text("Exit \(result.exitCode)")
                            .foregroundStyle(.secondary)
                        Text(BrewFormatters.formatDuration(result.duration))
                            .foregroundStyle(.secondary)
                        Spacer()
                        if let onDismiss {
                            Button(action: onDismiss) {
                                Image(systemName: "xmark")
                            }
                            .buttonStyle(.borderless)
                        }
                    }
                    Text(result.command)
                        .font(.system(.caption, design: .monospaced))
                        .foregroundStyle(.secondary)
                        .textSelection(.enabled)
                    ScrollView {
                        Text(result.output.isEmpty ? "No output." : result.output)
                            .font(.system(.body, design: .monospaced))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .textSelection(.enabled)
                    }
                    .frame(minHeight: 180, maxHeight: 320)
                }
            } else {
                Text("Run a utility or package action to see command output.")
                    .foregroundStyle(.secondary)
            }

            if !history.isEmpty {
                Divider()
                VStack(alignment: .leading, spacing: 6) {
                    Text("Recent")
                        .font(.subheadline.weight(.semibold))
                    ForEach(history.prefix(5)) { item in
                        HStack {
                            Image(systemName: item.succeeded ? "checkmark.circle" : "xmark.octagon")
                                .foregroundStyle(item.succeeded ? .green : .red)
                            Text(BrewFormatters.timestamp.string(from: item.finishedAt))
                                .foregroundStyle(.secondary)
                            Text(item.command)
                                .lineLimit(1)
                                .font(.system(.caption, design: .monospaced))
                        }
                    }
                }
            }
        }
    }
}
