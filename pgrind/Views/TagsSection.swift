import SwiftUI

struct TagsSection: View {
    var problem: ImageProblem
    @State private var newTag: String = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Tags").font(.headline)
            if !problem.tags.isEmpty {
                TagFlowLayout(spacing: 6) {
                    ForEach(problem.tags, id: \.self) { tag in
                        tagChip(tag)
                    }
                }
            }
            HStack {
                TextField("Add tag", text: $newTag)
                    .textFieldStyle(.roundedBorder)
                    .onSubmit(commitTag)
                Button("Add", action: commitTag)
                    .disabled(trimmedNewTag.isEmpty)
            }
        }
    }

    private func tagChip(_ tag: String) -> some View {
        HStack(spacing: 4) {
            Text(tag).font(.caption)
            Button {
                problem.tags.removeAll { $0 == tag }
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Capsule().fill(Color.secondary.opacity(0.15)))
    }

    private var trimmedNewTag: String {
        newTag.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func commitTag() {
        let tag = trimmedNewTag
        guard !tag.isEmpty else { return }
        if !problem.tags.contains(tag) {
            problem.tags.append(tag)
        }
        newTag = ""
    }
}
