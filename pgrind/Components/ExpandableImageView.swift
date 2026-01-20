import SwiftUI
import SwiftData

struct ExpandableImageView: View {
    let image: NSImage
    
    @State private var isExpanded: Bool = false
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            Image(nsImage: image)
                .resizable()
                .interpolation(.high)
                .scaledToFit()
                .frame(maxWidth: image.size.width, maxHeight: image.size.height)
                .onTapGesture { isExpanded = true }
                .overlay(alignment: .topTrailing) {
                    Button {
                        isExpanded = true
                    } label: {
                        Image(systemName: "arrow.up.left.and.arrow.down.right")
                            .font(.system(size: 14, weight: .semibold))
                            .padding(8)
                            .background(.thinMaterial)
                            .clipShape(Circle())
                            .shadow(radius: 2)
                    }
                    .buttonStyle(.plain)
                    .padding(8)
                }
        }
        .sheet(isPresented: $isExpanded) {
            ZStack {
                ScrollView {
                    Image(nsImage: image)
                        .resizable()
                        .interpolation(.high)
                        .scaledToFit()
                        .frame(maxWidth: image.size.width, maxHeight: image.size.height)
                }
                .padding()
                
                VStack {
                    HStack {
                        Spacer()
                        Button {
                            isExpanded = false
                        } label: {
                            Image(systemName: "xmark")
                                .font(.system(size: 16, weight: .bold))
                                .padding(10)
                                .background(.ultraThinMaterial)
                                .clipShape(Circle())
                        }
                        .buttonStyle(.plain)
                        .padding()
                    }
                    Spacer()
                }
            }
            .presentationSizing(.automatic)
        }
    }
}
