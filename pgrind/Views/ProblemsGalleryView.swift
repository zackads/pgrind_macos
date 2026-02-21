//
//  ProblemsGalleryView.swift
//  pgrind
//
//  Created by Zack Adlington on 21/02/2026.
//

import SwiftUI

struct ProblemsGalleryView: View {
    let problems: [Problem]
    var onSelect: (Problem) -> Void
    private let thumbSizeY: CGFloat = 300
    private var columns: [GridItem] {
        [GridItem(.adaptive(minimum: 350), spacing: 12)]
    }

    var body: some View {
        LazyVGrid(columns: columns, spacing: 12) {
            ForEach(problems, id: \.persistentModelID) { problem in
                Button {
                    onSelect(problem)
                } label: {
                    GalleryCell(problem: problem, sizeY: thumbSizeY)
                }
                .buttonStyle(.plain)
            }
        }
        .padding()
    }
}

private struct GalleryCell: View {
    let problem: Problem
    let sizeY: CGFloat
    @State private var availableWidth: CGFloat = 0

    var body: some View {
        let width = max(availableWidth, 1) // avoid divide-by-zero during initial layout
        let imageHeight = computedHeight(for: width)
        let pillHeight: CGFloat = 22
        let vSpacing: CGFloat = 6
        let totalHeight = imageHeight + vSpacing + pillHeight

        VStack(alignment: .center, spacing: vSpacing) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(.quaternary)

                switch problem {
                case let p as ImageProblem:
                    if let img = NSImage(data: p.questionImage) {
                        Image(nsImage: img)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                    } else {
                        Image(systemName: "photo")
                            .imageScale(.large)
                    }

                case _ as WebpageProblem:
                    Image(systemName: "globe")
                        .imageScale(.large)

                default:
                    Image(systemName: "questionmark")
                        .imageScale(.large)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: imageHeight)
            .clipShape(RoundedRectangle(cornerRadius: 10))

            Text(statusText)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(statusForeground)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(statusBackground, in: Capsule())
                .lineLimit(1)
                .frame(height: pillHeight)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(height: totalHeight, alignment: .top)
        .background(
            GeometryReader { geo in
                Color.clear
                    .onAppear { availableWidth = geo.size.width }
                    .onChange(of: geo.size.width) { _, newValue in
                        availableWidth = newValue
                    }
            }
        )
        .contentShape(RoundedRectangle(cornerRadius: 10))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityLabel)
    }

    private func computedHeight(for width: CGFloat) -> CGFloat {
        guard let p = problem as? ImageProblem,
              let img = NSImage(data: p.questionImage),
              img.size.width > 0
        else {
            return sizeY
        }

        let aspectRatio = img.size.height / img.size.width
        let scaledHeight = width * aspectRatio
        return min(scaledHeight, sizeY)
    }

    private var accessibilityLabel: String {
        switch problem {
        case let p as WebpageProblem:
            return "Webpage problem: \(p.name)"
        case _ as ImageProblem:
            return "Image problem"
        default:
            return "Problem"
        }
    }
    
    private var statusText: String {
        switch problem.currentDifficulty {
            case .notAttempted:
                return "Not attempted"
            case .easy:
                return "Easy"
            case .medium:
                return "Medium"
            case .hard:
                return "Hard"
        }
    }

    private var statusBackground: Color {
        switch problem.currentDifficulty {
            case .notAttempted: return .clear
            case .hard: return .red.opacity(0.25)
            case .medium: return .orange.opacity(0.25) // “amber”
            case .easy: return .green.opacity(0.25)
        }
    }

    private var statusForeground: Color {
        switch problem.currentDifficulty {
            case .notAttempted: return .secondary
            case .hard: return .red
            case .medium: return .orange
            case .easy: return .green
        }
    }
}

#Preview {
    let course = Course(title: "Calculus I", summary: "Learn Calculus", hyperlink: "example.com")
    let problemSet = ProblemSet(course: course, name: "Week 1")
    let sampleImage = NSImage(systemSymbolName: "doc.text.image", accessibilityDescription: nil)?
        .tiffRepresentation ?? Data()

    let imageProblem = ImageProblem(
        problemSet: problemSet,
        questionImage: Data(), solutionImage: nil, createdDate: Date())

    let webpageProblem = WebpageProblem(
        problemSet: problemSet,
        name: "Two Sum",
        questionURL: "example.com", solutionURL: "example.com")

    return ProblemsGalleryView(
        problems: [imageProblem, webpageProblem]
    ) { _ in }
    .padding()
}
