import SwiftData
import SwiftUI

struct HomeView: View {
    // Passed in explicitly (rather than resolved from @Environment) so the *same*
    // instance can be used to construct HomeViewModel in init() — @Environment isn't
    // resolved yet at init time.
    private let historyStore: CaseHistoryStore
    @StateObject private var viewModel: HomeViewModel

    // Reads go through @Query directly (SwiftData's idiomatic pattern) rather than
    // through historyStore, which only handles writes.
    @Query(sort: [SortDescriptor(\ScrubCase.createdAt, order: .reverse)]) private var allCases: [ScrubCase]

    init(historyStore: CaseHistoryStore) {
        self.historyStore = historyStore
        _viewModel = StateObject(wrappedValue: HomeViewModel(historyStore: historyStore))
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    if viewModel.selectedSpecialty == nil {
                        Text("Pick a specialty to get started")
                            .font(.title3.weight(.bold))
                            .foregroundStyle(Color.accentColor)
                            .transition(.opacity.combined(with: .move(edge: .top)))
                    }

                    if !viewModel.specialties.isEmpty {
                        SpecialtyRow(
                            specialties: viewModel.specialties,
                            selectedSpecialty: viewModel.selectedSpecialty,
                            onSelect: viewModel.selectSpecialty
                        )
                    }

                    CaseEntryCard(
                        caseDescription: $viewModel.caseDescription,
                        exampleChips: viewModel.exampleChips,
                        selectedSpecialty: viewModel.selectedSpecialty,
                        onSubmit: viewModel.prepareCase
                    )

                    VStack(spacing: 12) {
                        Button {
                            viewModel.startPimpMe()
                        } label: {
                            ActionCard(
                                title: "Pimp Me",
                                subtitle: "Test me before I scrub.",
                                description: "Interactive questions tailored to your case.",
                                systemImage: "flame.fill",
                                tint: .orange
                            )
                        }
                        .buttonStyle(.plain)
                        .disabled(!hasCaseDescription)
                        .opacity(hasCaseDescription ? 1 : 0.5)

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
                        .disabled(!hasCaseDescription)
                        .opacity(hasCaseDescription ? 1 : 0.5)

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

                    if !allCases.isEmpty {
                        recentCases
                    }
                }
                .padding()
                .animation(.easeInOut(duration: 0.3), value: viewModel.selectedSpecialty)
            }
            .navigationTitle("Scrub Prep")
            .navigationDestination(for: HomeRoute.self) { route in
                switch route {
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
            .navigationDestination(isPresented: $viewModel.navigateToPimpMe) {
                if let prep = viewModel.pimpMePrep {
                    PimpMeView(caseDescription: viewModel.caseDescription, prep: prep)
                }
            }
            .overlay {
                if viewModel.isGenerating {
                    LoadingView(
                        title: "Preparing your case\u{2026}",
                        messages: viewModel.loadingMessages,
                        onCancel: viewModel.cancelPreparing
                    )
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

    private var hasCaseDescription: Bool {
        !viewModel.caseDescription.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private var errorBinding: Binding<Bool> {
        Binding(
            get: { viewModel.errorMessage != nil },
            set: { if !$0 { viewModel.errorMessage = nil } }
        )
    }

    private var recentCases: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent Cases")
                .font(.title3.weight(.semibold))

            ForEach(allCases.prefix(5)) { scrubCase in
                RecentCaseRow(
                    scrubCase: scrubCase,
                    onReview: {
                        historyStore.markReviewed(scrubCase)
                        viewModel.generatedPrep = scrubCase.prep
                        viewModel.caseDescription = scrubCase.caseDescription
                        viewModel.navigateToPrep = true
                    },
                    onPimpMe: {
                        historyStore.markReviewed(scrubCase)
                        viewModel.caseDescription = scrubCase.caseDescription
                        viewModel.pimpMePrep = scrubCase.prep
                        viewModel.navigateToPimpMe = true
                    }
                )
            }
        }
    }
}

enum HomeRoute: Hashable {
    case rapidFire
    case firstDay
}

#Preview {
    let container = try! ModelContainer(for: ScrubCase.self, PimpMeSession.self, configurations: .init(isStoredInMemoryOnly: true))
    HomeView(historyStore: CaseHistoryStore(modelContext: container.mainContext))
        .modelContainer(container)
}
