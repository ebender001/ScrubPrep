import SwiftUI

/// "Pimp Me" / "Rapid Fire" launch buttons and the My Notes button at the bottom of an
/// OR Prep.
struct PrepActionButtons: View {
    let caseDescription: String
    let prep: ORPrep
    /// Presents the My Notes sheet — owned by `PrepView`, which also opens it from the
    /// toolbar.
    let onShowNotes: () -> Void

    var body: some View {
        VStack(spacing: 10) {
            NavigationLink {
                PimpMeView(caseDescription: caseDescription, prep: prep)
            } label: {
                Label("Quiz Me", systemImage: "flame.fill")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 4)
            }
            .buttonStyle(.borderedProminent)

            NavigationLink {
                RapidFireView(caseDescription: caseDescription, prep: prep)
            } label: {
                Label("Rapid Fire", systemImage: "bolt.fill")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 4)
            }
            .buttonStyle(.bordered)

            Button(action: onShowNotes) {
                Label("My Notes", systemImage: "note.text")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 4)
            }
            .buttonStyle(.bordered)
        }
        .padding(.top, 8)
    }
}

#Preview {
    NavigationStack {
        PrepActionButtons(caseDescription: "Lap chole for acute cholecystitis", prep: .mockLapChole, onShowNotes: {})
    }
}
