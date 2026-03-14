import SwiftUI

struct HistoryView: View {
    let viewModel: SoundViewModel

    var body: some View {
        NavigationStack {
            List(viewModel.jobs) { job in
                HStack {
                    VStack(alignment: .leading, spacing: SoundItSpacing.xxs) {
                        Text(job.id)
                            .font(SoundItFont.caption())
                            .monospaced()
                            .foregroundStyle(SoundItColors.cream)
                            .lineLimit(1)
                        Text(job.createdAt)
                            .font(SoundItFont.caption(11))
                            .foregroundStyle(SoundItColors.smoke)
                    }
                    Spacer()
                    SoundItStatusBadge(text: job.status, color: statusColor(for: job.status))
                }
                .listRowBackground(SoundItColors.cocoa)
            }
            .scrollContentBackground(.hidden)
            .soundItBackground()
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
                    VStack(spacing: SoundItSpacing.md) {
                        Image(systemName: "clock")
                            .font(.system(size: 48, weight: .bold))
                            .foregroundStyle(SoundItColors.leather)
                        Text("NO JOBS")
                            .font(SoundItFont.headline())
                            .foregroundStyle(SoundItColors.smoke)
                        Text("Generated videos will appear here.")
                            .font(SoundItFont.body())
                            .foregroundStyle(SoundItColors.smoke)
                    }
                }
            }
        }
    }

    private func statusColor(for status: String) -> Color {
        switch status {
        case "completed": SoundItColors.success
        case "failed": SoundItColors.error
        case "processing", "pending": SoundItColors.processing
        default: SoundItColors.foxyOrange
        }
    }
}
