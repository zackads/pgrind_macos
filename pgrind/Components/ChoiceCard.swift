import SwiftUI

struct ChoiceCard: View {
    let title: String
    let summary: String?
    let hyperlink: URL?
    let isSelected: Bool
    let systemImage: String

    init(
        title: String,
        summary: String? = nil,
        hyperlink: URL? = nil,
        isSelected: Bool = false,
        systemImage: String = "book.closed"
    ) {
        self.title = title
        self.summary = summary
        self.hyperlink = hyperlink
        self.isSelected = isSelected
        self.systemImage = systemImage
    }

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: systemImage)
                .font(.title2)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                if let summary {
                    Text(summary)
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .lineLimit(3)
                        .fixedSize(horizontal: false, vertical: true)
                        .multilineTextAlignment(.leading)
                }
                if let hyperlink {
                    Link(hyperlink.absoluteString, destination: hyperlink)
                        .font(.footnote)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            if isSelected {
                Image(systemName: "checkmark.circle.fill")
                    .font(.title3)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.quaternary, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

#Preview("With summary and hyperlink") {
    ChoiceCard(
        title: "MIT 18.100A | Real Analysis | Fall 2020",
        summary: "This course covers the fundamentals of mathematical analysis: convergence of sequences and series, continuity, differentiability, Riemann integral, sequences and series of functions, uniformity, and the interchange of limit operations. It shows the utility of abstract concepts through a study of real numbers, and teaches an understanding and construction of proofs.",
        hyperlink: URL(string: "https://ocw.mit.edu/courses/18-100a-real-analysis-fall-2020/")
    )
}

#Preview("No summary") {
    ChoiceCard(
        title: "MIT 18.100A | Real Analysis | Fall 2020",
        hyperlink: URL(string: "https://ocw.mit.edu/courses/18-100a-real-analysis-fall-2020/")
    )
}

#Preview("No hyperlink") {
    ChoiceCard(
        title: "MIT 18.100A | Real Analysis | Fall 2020",
        summary: "This course covers the fundamentals of mathematical analysis: convergence of sequences and series, continuity, differentiability, Riemann integral, sequences and series of functions, uniformity, and the interchange of limit operations. It shows the utility of abstract concepts through a study of real numbers, and teaches an understanding and construction of proofs.",
    )
}
