import SwiftUI

/// A titled card containing a bulleted list — the primary building block of PrepView.
struct SectionCard: View {
    let title: String
    let systemImage: String
    let items: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label(title, systemImage: systemImage)
                .font(.headline)

            VStack(alignment: .leading, spacing: 6) {
                ForEach(items, id: \.self) { item in
                    HStack(alignment: .top, spacing: 8) {
                        Circle()
                            .fill(Color.accentColor)
                            .frame(width: 5, height: 5)
                            .padding(.top, 7)
                        Text(item)
                            .font(.subheadline)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.thinMaterial, in: .rect(cornerRadius: 16))
    }
}

#Preview {
    ScrollView {
        SectionCard(
            title: "Anatomy I need to know",
            systemImage: "figure.stand",
            items: ["Cystic duct", "Cystic artery", "Common bile duct"]
        )
        .padding()
    }
}
