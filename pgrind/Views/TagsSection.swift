import SwiftData
import SwiftUI

struct TagsSection: View {
    var problem: ImageProblem
    @State private var newTag: String = ""
    @Query private var allProblems: [ImageProblem]

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
            if !suggestions.isEmpty {
                TagFlowLayout(spacing: 6) {
                    ForEach(suggestions, id: \.self) { suggestion in
                        suggestionChip(suggestion)
                    }
                }
            }
        }
    }

    private var suggestions: [String] {
        let query = trimmedNewTag.lowercased()
        guard !query.isEmpty else { return [] }
        let existing = Set(problem.tags)
        var seen = Set<String>()
        var results: [String] = []
        for problem in allProblems {
            for tag in problem.tags {
                guard !existing.contains(tag), !seen.contains(tag) else { continue }
                if tag.lowercased().contains(query) {
                    seen.insert(tag)
                    results.append(tag)
                }
            }
        }
        return results.sorted().prefix(8).map { $0 }
    }

    private func suggestionChip(_ tag: String) -> some View {
        Button {
            if !problem.tags.contains(tag) {
                problem.tags.append(tag)
            }
            newTag = ""
        } label: {
            Text(tag)
                .font(.caption)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Capsule().fill(Color.accentColor.opacity(0.15)))
        }
        .buttonStyle(.plain)
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
