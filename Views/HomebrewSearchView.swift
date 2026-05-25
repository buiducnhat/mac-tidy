import SwiftUI

struct HomebrewSearchView: View {
    @Bindable var store: BrewStore

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 10) {
                TextField("Formula or cask name", text: $store.searchTerm)
                    .textFieldStyle(.roundedBorder)
                    .onSubmit {
                        Task { await store.performSearch() }
                    }
                Button {
                    Task { await store.performSearch() }
                } label: {
                    Label("Search", systemImage: "magnifyingglass")
                }
                .disabled(store.searchTerm.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            .padding(16)
            .background(.bar)

            if store.searchResults.isEmpty {
                ContentUnavailableView("Search formulae and casks", systemImage: "magnifyingglass")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List(store.searchResults, selection: $store.selectedPackageID) { package in
                    HStack(spacing: 12) {
                        Image(systemName: package.kind == .cask ? "macwindow" : "terminal")
                            .foregroundStyle(.secondary)
                            .frame(width: 18)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(package.name)
                            Text(package.kind.rawValue)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Button {
                            Task { await store.installSearchResult(package) }
                        } label: {
                            Label("Install", systemImage: "plus.circle")
                        }
                        .buttonStyle(.borderless)
                    }
                    .padding(.vertical, 4)
                    .tag(package.id)
                }
            }
        }
        .navigationTitle("Search")
    }
}
