import SwiftUI

struct TagFlowLayout: Layout {
    var spacing: CGFloat = 6

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache _: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        let rows = computeRows(maxWidth: maxWidth, subviews: subviews)
        let height = rows.reduce(CGFloat(0)) { $0 + $1.height + spacing } - (rows.isEmpty ? 0 : spacing)
        let width = rows.map(\.width).max() ?? 0
        return CGSize(width: min(width, maxWidth), height: max(height, 0))
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache _: inout ()) {
        let maxWidth = proposal.width ?? bounds.width
        let rows = computeRows(maxWidth: maxWidth, subviews: subviews)
        var posY = bounds.minY
        for row in rows {
            var posX = bounds.minX
            for index in row.indices {
                let size = subviews[index].sizeThatFits(.unspecified)
                subviews[index].place(
                    at: CGPoint(x: posX, y: posY),
                    anchor: .topLeading,
                    proposal: ProposedViewSize(size)
                )
                posX += size.width + spacing
            }
            posY += row.height + spacing
        }
    }

    private struct Row {
        var indices: [Int] = []
        var width: CGFloat = 0
        var height: CGFloat = 0
    }

    private func computeRows(maxWidth: CGFloat, subviews: Subviews) -> [Row] {
        var rows: [Row] = [Row()]
        for index in subviews.indices {
            let size = subviews[index].sizeThatFits(.unspecified)
            let projected = rows[rows.count - 1].width + size.width
                + (rows[rows.count - 1].indices.isEmpty ? 0 : spacing)
            if projected > maxWidth, !rows[rows.count - 1].indices.isEmpty {
                rows.append(Row())
            }
            let last = rows.count - 1
            if !rows[last].indices.isEmpty { rows[last].width += spacing }
            rows[last].indices.append(index)
            rows[last].width += size.width
            rows[last].height = max(rows[last].height, size.height)
        }
        return rows
    }
}
