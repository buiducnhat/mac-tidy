import MacTidyCore
import SwiftUI

struct DashboardView: View {
    let scanStore: ScanStore

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                HStack(spacing: 12) {
                    Image(systemName: "gauge.with.dots.needle.67percent")
                        .font(.system(size: 30, weight: .semibold))
                        .foregroundStyle(.tint)
                        .frame(width: 44, height: 44)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Dashboard")
                            .font(.title2.weight(.semibold))
                        Text("Scan summaries appear here after Analyze runs.")
                            .foregroundStyle(.secondary)
                    }
                }

                if let summary = scanStore.summary {
                    Grid(alignment: .leading, horizontalSpacing: 28, verticalSpacing: 10) {
                        GridRow {
                            SummaryMetric(title: "Items", value: "\(summary.itemCount)")
                            SummaryMetric(title: "Total Size", value: ByteFormatter.string(from: summary.totalBytes))
                            SummaryMetric(title: "Diagnostics", value: "\(summary.diagnosticsCount)")
                        }
                    }
                } else {
                    ContentUnavailableView {
                        Label("No Scan Yet", systemImage: "magnifyingglass.circle")
                    } description: {
                        Text("Open Analyze to run a non-destructive scan.")
                    }
                }
            }
            .padding(28)
        }
    }
}

private struct SummaryMetric: View {
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(value)
                .font(.title3.weight(.semibold))
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(minWidth: 120, alignment: .leading)
    }
}
