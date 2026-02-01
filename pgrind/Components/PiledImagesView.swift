//
//  PiledImagesView.swift
//  pgrind
//
//  Created by Zack Adlington on 01/02/2026.
//

import SwiftUI

struct PiledImagesView: View {
    let imagesData: [Data]

    var body: some View {
        ZStack {
            ForEach(Array(imagesData.enumerated()), id: \.offset) { index, data in
                if let img = NSImage(data: data) {
                    Image(nsImage: img)
                        .resizable()
                        .scaledToFit()
                        .rotationEffect(.degrees(Double(index % 5 - 2) * 2))
                        .offset(x: CGFloat(index % 3 - 1) * 8, y: CGFloat(index % 3 - 1) * -8)
                        .shadow(radius: 3, y: 2)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 240)
        .padding(6)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
}
