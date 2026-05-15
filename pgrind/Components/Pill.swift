//
//  Pill.swift
//  pgrind
//
//  Created by Zack Adlington on 15/05/2026.
//

import SwiftUI

struct Pill: View {
    var text: String
    var foreground: Color = .primary
    var background: Color = .secondary
    var height: CGFloat = 22

    var body: some View {
        Text(text)
            .font(.caption)
            .fontWeight(.semibold)
            .foregroundStyle(foreground)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(background, in: Capsule())
            .lineLimit(1)
            .frame(height: height)
    }
}
