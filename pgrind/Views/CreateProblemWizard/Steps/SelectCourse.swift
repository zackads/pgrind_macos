import SwiftUI
import SwiftData

struct SelectCourse: View {
    @Environment(\.dismiss) private var dismiss
    
    private enum Selection: Equatable {
        case none
        case existing(Course)
        case new
    }
    
    @Binding var path: [CreateProblemWizard.Route]
    @Binding var course: Course?
    var onCancel: () -> Void
    
    @State private var selection: Selection = .none
    
    @Query(sort: \Course.createdDate, order: .reverse) private var courses: [Course]
    
    var body: some View {
        Form {
            ScrollView{
                ForEach(courses) { choice in
                    Button(action: {
                        selection = .existing(choice)
                    }) {
                        ChoiceCard(
                            title: choice.title,
                            summary: choice.summary,
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
                            Text("Add a new course")
                                .font(.headline)
                            Text("Create a course to organize your problems.")
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
        .navigationTitle("Select a course")
        .onAppear {
            if let newestCourse = courses.first {
                selection = .existing(newestCourse)
            } else {
                selection = .new
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
                        path.append(.createCourse)
                    case .existing(let selectedCourse):
                        course = selectedCourse
                        path.append(.selectProblemSet(selectedCourse))
                    case .none:
                        fatalError("Invalid state")
                    }
                }
                .disabled(selection == .none)
            }
        }
    }
}

private struct SelectCoursePreviewHost: View {
    @State private var path: [CreateProblemWizard.Route] = []
    @State private var selectedCourse: Course? = nil
    
    var body: some View {
        NavigationStack(path: $path) {
            SelectCourse(path: $path, course: $selectedCourse, onCancel: {})
                .navigationTitle("Select course")
        }
    }
}

private struct SelectCourseWithCoursesPreviewHost: View {
    @State private var path: [CreateProblemWizard.Route] = []
    @State private var selectedCourse: Course? = nil
    
    private let container: ModelContainer = {
        do {
            let container = try ModelContainer(
                for: Course.self,
                configurations: ModelConfiguration(isStoredInMemoryOnly: true)
            )
            
            let context = container.mainContext
            
            context.insert(
                Course(
                    title: "MIT 18.01 | Single Variable Calculus | Fall 2020",
                    summary: "Master the calculus of derivatives, integrals, coordinate systems, and infinite series.",
                    hyperlink: "https://ocw.mit.edu/courses/18-01-calculus-i-single-variable-calculus-fall-2020/"
                )
            )
            
            context.insert(
                Course(
                    title: "MIT 6.033 | Computer System Engineering | Spring 2018",
                    summary: "This class covers topics on the engineering of computer software and hardware systems. Topics include techniques for controlling complexity; strong modularity using client-server design, operating systems; performance, networks; naming; security and privacy; fault-tolerant systems, atomicity and coordination of concurrent activities, and recovery; impact of computer systems on society.",
                    hyperlink:  "https://ocw.mit.edu/courses/6-033-computer-system-engineering-spring-2018/"
                )
            )
            
            context.insert(
                Course(
                    title: "MIT 18.100A | Real Analysis | Fall 2020",
                    summary: "This course covers the fundamentals of mathematical analysis: convergence of sequences and series, continuity, differentiability, Riemann integral, sequences and series of functions, uniformity, and the interchange of limit operations. It shows the utility of abstract concepts through a study of real numbers, and teaches an understanding and construction of proofs.",
                    hyperlink: "https://ocw.mit.edu/courses/18-100a-real-analysis-fall-2020/"
                )
            )
            
            return container
        } catch {
            fatalError("Failed to create preview container: \(error)")
        }
    }()
    
    var body: some View {
        NavigationStack(path: $path) {
            SelectCourse(path: $path, course: $selectedCourse, onCancel: {})
                .navigationTitle("Select course")
        }
        .modelContainer(container)
    }
}

#Preview("No courses") {
    SelectCoursePreviewHost()
}

#Preview("With courses") {
    SelectCourseWithCoursesPreviewHost()
}

