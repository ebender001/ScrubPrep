import SwiftUI

struct HomeView: View {
    @StateObject private var viewModel = HomeViewModel()

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
                                tint: .orange,
                                lockedMessage: viewModel.isCurrentCasePrepared ? nil : "Unlocks after Prepare Me"
                            )
                        }
                        .buttonStyle(.plain)
                        .disabled(!viewModel.isCurrentCasePrepared)
                        .opacity(viewModel.isCurrentCasePrepared ? 1 : 0.5)

                        Button {
                            viewModel.startRapidFire()
                        } label: {
                            ActionCard(
                                title: "Rapid Fire",
                                subtitle: "2 minutes before the OR.",
                                description: "Five high-yield questions. No lengthy explanations.",
                                systemImage: "bolt.fill",
                                tint: .yellow,
                                lockedMessage: viewModel.isCurrentCasePrepared ? nil : "Unlocks after Prepare Me"
                            )
                        }
                        .buttonStyle(.plain)
                        .disabled(!viewModel.isCurrentCasePrepared)
                        .opacity(viewModel.isCurrentCasePrepared ? 1 : 0.5)

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

                    if !viewModel.recentCases.isEmpty {
                        recentCases
                    }
                }
                .padding()
                .animation(.easeInOut(duration: 0.3), value: viewModel.selectedSpecialty)
            }
            .navigationTitle("Scrub Prep")
            .task {
                await viewModel.loadCases()
            }
            .navigationDestination(for: HomeRoute.self) { route in
                switch route {
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
            .navigationDestination(isPresented: $viewModel.navigateToRapidFire) {
                if let prep = viewModel.rapidFirePrep {
                    RapidFireView(caseDescription: viewModel.caseDescription, prep: prep)
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
            .sheet(isPresented: $viewModel.showPaywall) {
                PaywallView(onPurchaseCompleted: viewModel.resumeAfterSubscribing)
            }
        }
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

            ForEach(viewModel.recentCases.prefix(5)) { scrubCase in
                RecentCaseRow(
                    scrubCase: scrubCase,
                    onReview: {
                        Task { await viewModel.reviewRecentCase(scrubCase) }
                    },
                    onPimpMe: {
                        Task { await viewModel.startPimpMeFromRecentCase(scrubCase) }
                    },
                    onRapidFire: {
                        Task { await viewModel.startRapidFireFromRecentCase(scrubCase) }
                    }
                )
            }
        }
    }
}

enum HomeRoute: Hashable {
    case firstDay
}

#Preview {
    HomeView()
}
