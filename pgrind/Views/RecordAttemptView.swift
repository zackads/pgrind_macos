import SwiftData
import SwiftUI

struct RecordAttemptView: View {
    enum Tab: Hashable {
        case question, solution
    }

    @Environment(\.modelContext) var modelContext
    @Environment(\.dismiss) var dismiss

    @Binding var path: [Home.Route]
    var problem: ImageProblem
    @State private var selectedDifficulty: Difficulty = .medium
    @State private var selectedTab: Tab = .question
    @State private var notes: String = ""
    @State private var questionReplacementData: [Data] = []
    @State private var solutionReplacementData: [Data] = []

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Spacer()

                TabView(selection: $selectedTab) {
                    ScrollView {
                        VStack(spacing: 16) {
                            replaceableImage(
                                data: problem.questionImage,
                                missingLabel: "Missing question image",
                                replacementData: $questionReplacementData,
                                onCommit: { merged in problem.questionImage = merged }
                            )
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                    }
                    .tabItem { Label("Question", systemImage: "doc.text") }
                    .tag(Tab.question)

                    ScrollView {
                        VStack(spacing: 16) {
                            replaceableImage(
                                data: problem.solutionImage,
                                missingLabel: "Missing solution image",
                                replacementData: $solutionReplacementData,
                                onCommit: { merged in problem.solutionImage = merged }
                            )

                            HStack {
                                Spacer()
                                Picker("", selection: $selectedDifficulty) {
                                    let difficulties = Difficulty.allCases.filter { $0 != .notAttempted }
                                    ForEach(difficulties, id: \.self) { difficulty in
                                        Text(String(describing: difficulty)).tag(difficulty)
                                    }
                                }
                                .pickerStyle(.segmented)
                                Spacer()
                            }

                            TagsSection(problem: problem)
                                .frame(maxWidth: .infinity, alignment: .leading)

                            VStack(alignment: .leading, spacing: 8) {
                                Text("Notes").font(.headline)
                                TextEditor(text: $notes)
                                    .scrollContentBackground(.hidden)
                                    .frame(minHeight: 140)
                                    .frame(maxWidth: .infinity)
                                    .padding(12)
                                    .background(
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(Color.secondary.opacity(0.08))
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .strokeBorder(Color.secondary.opacity(0.3))
                                    )
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)

                            previousNotesTimeline
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .padding()
                    }
                    .tabItem { Label("Solution", systemImage: "checkmark.circle") }
                    .tag(Tab.solution)
                }
            }
        }
        .padding()
        .navigationTitle("Record attempt")
        .toolbar { toolbarContent }
    }

    @ViewBuilder
    private func replaceableImage(
        data: Data?,
        missingLabel: String,
        replacementData: Binding<[Data]>,
        onCommit: @escaping (Data) -> Void
    ) -> some View {
        if !replacementData.wrappedValue.isEmpty {
            replacementInProgress(replacementData: replacementData, onCommit: onCommit)
        } else {
            currentImageWithReplaceButton(
                data: data,
                missingLabel: missingLabel,
                replacementData: replacementData
            )
        }
    }

    private func appendScreenshot(to replacementData: Binding<[Data]>) {
        Task { @MainActor in
            if let newData = await Screenshotter.takeScreenshot() {
                replacementData.wrappedValue.append(newData)
            }
        }
    }

    private func replacementInProgress(
        replacementData: Binding<[Data]>,
        onCommit: @escaping (Data) -> Void
    ) -> some View {
        VStack(spacing: 12) {
            PiledImagesView(imagesData: replacementData.wrappedValue)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            HStack {
                Button {
                    appendScreenshot(to: replacementData)
                } label: {
                    Label("Add another screenshot", systemImage: "plus")
                }
                .buttonStyle(.bordered)
                .controlSize(.large)

                Button {
                    if let merged = Screenshotter.mergeImagesVertically(from: replacementData.wrappedValue) {
                        onCommit(merged)
                        replacementData.wrappedValue.removeAll()
                    }
                } label: {
                    Label("Save replacement", systemImage: "checkmark")
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)

                Button(role: .destructive) {
                    replacementData.wrappedValue.removeAll()
                } label: {
                    Label("Cancel", systemImage: "xmark")
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
            }
        }
        .frame(maxWidth: .infinity)
    }

    private func currentImageWithReplaceButton(
        data: Data?,
        missingLabel: String,
        replacementData _: Binding<[Data]>
    ) -> some View {
        VStack(spacing: 12) {
            if let data, let image = NSImage(data: data) {
                ExpandableImageView(image: image, maxSize: nil)
                    .frame(maxWidth: .infinity)
            } else {
                ContentUnavailableView(missingLabel, systemImage: "photo")
                    .frame(maxWidth: .infinity)
            }
        }
        .frame(maxWidth: .infinity)
    }

    private var pastAttemptsWithNotes: [Attempt] {
        problem.attempts
            .filter { ($0.notes?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false) }
            .sorted { $0.createdDate > $1.createdDate }
    }

    @ViewBuilder
    private var previousNotesTimeline: some View {
        let attempts = pastAttemptsWithNotes
        if !attempts.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                Text("Previous notes").font(.headline)
                VStack(alignment: .leading, spacing: 12) {
                    ForEach(attempts) { attempt in
                        HStack(alignment: .top, spacing: 12) {
                            VStack(spacing: 4) {
                                Circle()
                                    .fill(Color.accentColor)
                                    .frame(width: 8, height: 8)
                                Rectangle()
                                    .fill(Color.secondary.opacity(0.3))
                                    .frame(width: 1)
                                    .frame(maxHeight: .infinity)
                            }
                            VStack(alignment: .leading, spacing: 4) {
                                HStack(spacing: 8) {
                                    Text(attempt.createdDate, format: .dateTime.year().month().day().hour().minute())
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                    Text(String(describing: attempt.difficulty))
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                Text(attempt.notes ?? "")
                                    .font(.body)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.bottom, 4)
                        }
                    }
                }
            }
        }
    }

    private var activeReplacementBinding: Binding<[Data]> {
        switch selectedTab {
        case .question: $questionReplacementData
        case .solution: $solutionReplacementData
        }
    }

    private var activeImageMissing: Bool {
        switch selectedTab {
        case .question: problem.questionImage.isEmpty
        case .solution: problem.solutionImage == nil
        }
    }

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .primaryAction) {
            Button {
                appendScreenshot(to: activeReplacementBinding)
            } label: {
                Label(
                    activeImageMissing ? "Add screenshot" : "Replace image",
                    systemImage: "camera.viewfinder"
                )
            }
            .disabled(!activeReplacementBinding.wrappedValue.isEmpty)
        }

        ToolbarItem(placement: .confirmationAction) {
            Button("Save") {
                problem.attempts.append(
                    Attempt(
                        problem: problem,
                        difficulty: selectedDifficulty,
                        notes: notes
                    )
                )
                problem.inInbox = false

                dismiss()
            }
            .keyboardShortcut(.defaultAction)
        }
    }
}

#Preview("ImageProblem") {
    let course = Course(
        title: "Test course",
        summary: "A test course for testing purposes",
        hyperlink: "http://example.com/course"
    )
    let problemSet = ProblemSet(course: course, name: "Week 3")
    let problem = ImageProblem(
        problemSet: problemSet,
        questionImage: Data(),
        solutionImage: Data()
    )
    RecordAttemptView(path: .constant([]), problem: problem)
}
