import SwiftUI

struct HistoryView: View {
    let viewModel: SoundViewModel

    var body: some View {
        NavigationStack {
            List(viewModel.jobs) { job in
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(job.id)
                            .font(.caption.monospaced())
                            .lineLimit(1)
                        Text(job.createdAt)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    StatusBadge(status: job.status)
                }
            }
            .navigationTitle("History")
            .navigationBarTitleDisplayMode(.inline)
            .task {
                await viewModel.loadJobs()
            }
            .refreshable {
                await viewModel.loadJobs()
            }
            .overlay {
                if viewModel.jobs.isEmpty {
                    ContentUnavailableView(
                        "No Jobs",
                        systemImage: "clock",
                        description: Text("Generated videos will appear here.")
                    )
                }
            }
        }
    }
}

// MARK: - Status Badge

private struct StatusBadge: View {
    let status: String

    var body: some View {
        Text(status.capitalized)
            .font(.caption2.bold())
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(color.opacity(0.15))
            .foregroundStyle(color)
            .clipShape(Capsule())
    }

    private var color: Color {
        switch status {
        case "completed": .green
        case "failed": .red
        case "processing": .blue
        default: .orange
        }
    }
}
