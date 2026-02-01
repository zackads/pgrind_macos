import SwiftUI
import SwiftData


struct SelectProblemKind: View {
    @Environment(\.dismiss) var dismiss
    
    @Binding var path: [CreateProblemWizard.Route]
    let problemSet: ProblemSet
    @Binding var selectedProblemKind: ProblemKind?
    let onCancel: () -> Void
    
    var body: some View {
        Form {
            Section {
                choiceCard(
                    title: "Image problem",
                    summary: "The problem and solution are both images.  For example, a question from a past exam paper or homework problem sheet.",
                    isSelected: selectedProblemKind == .image,
                    systemName: "photo"
                ) {
                    selectedProblemKind = .image
                }
                
                choiceCard(
                    title: "Webpage problem",
                    summary: "The problem and solution are links to webpages.  For example, a Leetcode problem with a YouTube video solution.",
                    isSelected: selectedProblemKind == .webpage,
                    systemName: "safari"
                ) {
                    selectedProblemKind = .webpage
                }
            }
        }
        .navigationTitle("What kind of problem?")
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") {
                    onCancel()
                }
            }
            
            ToolbarItem(placement: .confirmationAction) {
                Button("Continue") {
                    if selectedProblemKind == .image {
                        path.append(.createImageProblemQuestion(problemSet))
                    } else {
                        path.append(.createWebpageProblem(problemSet))
                    }
                }
                .disabled(selectedProblemKind == nil)
            }
        }
    }
    
    private func choiceCard(
        title: String,
        summary: String,
        isSelected: Bool,
        systemName: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: systemName)
                    .font(.title2)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                    Text(summary)
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .lineLimit(3)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title3)
                }
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.quaternary)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    @Previewable @State var path: [CreateProblemWizard.Route] = []
    @Previewable @State var kind: ProblemKind? = nil
    let course = Course(title: "Calculus I", summary: "Learn how to differentiate and integrate", hyperlink: "https://www.calculus.com")
    let problemSet = ProblemSet(course: course, name: "Week 1 problem sheet")
    
    SelectProblemKind(path: $path, problemSet: problemSet, selectedProblemKind: $kind, onCancel: {})
}

#Preview("Inside NavigationStack") {
    @Previewable @State var path: [CreateProblemWizard.Route] = []
    @Previewable @State var kind: ProblemKind? = nil
    let course = Course(title: "Calculus I", summary: "Learn how to differentiate and integrate", hyperlink: "https://www.calculus.com")
    let problemSet = ProblemSet(course: course, name: "Week 1 problem sheet")

    NavigationStack {
        SelectProblemKind(path: $path, problemSet: problemSet, selectedProblemKind: $kind, onCancel: {})
    }
}
