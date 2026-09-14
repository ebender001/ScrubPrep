import SwiftUI

struct HomeView: View {
    // Passed in explicitly (rather than @EnvironmentObject) so the *same* store instance
    // can be used to construct HomeViewModel in init() — @EnvironmentObject isn't resolved
    // yet at init time, which would otherwise lead to two disconnected store instances.
    @ObservedObject private var historyStore: CaseHistoryStore
    @StateObject private var viewModel: HomeViewModel

    init(historyStore: CaseHistoryStore) {
        self.historyStore = historyStore
        _viewModel = StateObject(wrappedValue: HomeViewModel(historyStore: historyStore))
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    header

                    CaseEntryCard(
                        caseDescription: $viewModel.caseDescription,
                        exampleChips: viewModel.exampleChips,
                        onSubmit: viewModel.prepareCase
                    )

                    VStack(spacing: 12) {
                        NavigationLink(value: HomeRoute.pimpMe) {
                            ActionCard(
                                title: "Pimp Me",
                                subtitle: "Test me before I scrub.",
                                description: "Interactive questions tailored to your case.",
                                systemImage: "flame.fill",
                                tint: .orange
                            )
                        }
                        .buttonStyle(.plain)

                        NavigationLink(value: HomeRoute.rapidFire) {
                            ActionCard(
                                title: "Rapid Fire",
                                subtitle: "2 minutes before the OR.",
                                description: "Five high-yield questions. No lengthy explanations.",
                                systemImage: "bolt.fill",
                                tint: .yellow
                            )
                        }
                        .buttonStyle(.plain)

                        NavigationLink(value: HomeRoute.firstDay) {
                            ActionCard(
                                title: "First Day?",
                                subtitle: "New to the surgery rotation?",
                                description: "Learn rounds, scrubbing, OR etiquette, presentations, and what your team expects.",
                                systemImage: "sparkles",
                                tint: .blue
                            )
                        }
                        .buttonStyle(.plain)
                    }

                    if !historyStore.cases.isEmpty {
                        recentCases
                    }
                }
                .padding()
            }
            .navigationTitle("Scrub Prep")
            .navigationDestination(for: HomeRoute.self) { route in
                switch route {
                case .pimpMe:
                    PimpMePlaceholderView(caseDescription: nil, prep: nil)
                case .rapidFire:
                    RapidFirePlaceholderView(caseDescription: nil, prep: nil)
                case .firstDay:
                    FirstDayView()
                }
            }
            .navigationDestination(isPresented: $viewModel.navigateToPrep) {
                if let prep = viewModel.generatedPrep {
                    PrepView(caseDescription: viewModel.caseDescription, prep: prep)
                }
            }
            .overlay {
                if viewModel.isGenerating {
                    LoadingView(title: "Preparing your case\u{2026}", messages: viewModel.loadingMessages)
                        .background(.regularMaterial)
                }
            }
            .alert("Couldn't prepare this case", isPresented: errorBinding) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(viewModel.errorMessage ?? "")
            }
        }
    }

    private var errorBinding: Binding<Bool> {
        Binding(
            get: { viewModel.errorMessage != nil },
            set: { if !$0 { viewModel.errorMessage = nil } }
        )
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Be ready for surgery.")
                .font(.title3.weight(.medium))
                .foregroundStyle(.secondary)
            Text("Created by a former Stanford surgery professor")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
    }

    private var recentCases: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent Cases")
                .font(.title3.weight(.semibold))

            ForEach(historyStore.cases.prefix(5)) { scrubCase in
                RecentCaseRow(
                    scrubCase: scrubCase,
                    onReview: {
                        historyStore.markReviewed(scrubCase)
                        viewModel.generatedPrep = scrubCase.prep
                        viewModel.caseDescription = scrubCase.caseDescription
                        viewModel.navigateToPrep = true
                    },
                    onPimpMe: {}
                )
            }
        }
    }
}

enum HomeRoute: Hashable {
    case pimpMe
    case rapidFire
    case firstDay
}

#Preview {
    HomeView(historyStore: CaseHistoryStore())
}
