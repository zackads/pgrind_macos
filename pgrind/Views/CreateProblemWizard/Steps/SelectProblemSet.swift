import SwiftUI
import SwiftData

struct SelectProblemSet: View {
    @Environment(\.dismiss) private var dismiss
    
    private enum Selection: Equatable {
        case none
        case existing(ProblemSet)
        case new
    }
    
    @Binding var path: [Route]
    var course: Course
    @Binding var selectedProblemSet: ProblemSet?
    var onCancel: () -> Void
    
    @State private var selection: Selection = .none
    
    var body: some View {
        Form {
            ScrollView{
                ForEach(course.problemSets) { choice in
                    Button(action: {
                        selection = .existing(choice)
                    }) {
                        ChoiceCard(
                            title: choice.name,
                            isSelected: {
                                if case .existing(let c) = selection {
                                    return c == choice
                                } else {
                                    return false
                                }
                            }()
                        )
                    }
                    .buttonStyle(.plain)
                }
                
                Button(action: {
                    selection = .new
                }) {
                    HStack(spacing: 12) {
                        Image(systemName: "plus.circle")
                            .font(.title2)
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Add a new problem set")
                                .font(.headline)
                            Text("Divide a course into problem sets, such as by week, chapter or exam paper.")
                                .font(.body)
                                .foregroundStyle(.secondary)
                                .lineLimit(2)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        
                        if selection == .new {
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
        .navigationTitle("Select a problem set in \(course.title)")
        .onAppear {
            if let newestSection = course.problemSets.first {
                selection = .existing(newestSection)
            } else {
                selection = .none
            }
        }
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") {
                    onCancel()
                }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Continue") {
                    switch selection {
                    case .new:
                        path.append(.createProblemSet(course))
                    case .existing(let selectedSection):
                        path.append(.selectProblemKind(selectedSection))
                    case .none:
                        fatalError("Invalid state")
                    }
                }
                .disabled(selection == .none)
            }
        }
    }
}
