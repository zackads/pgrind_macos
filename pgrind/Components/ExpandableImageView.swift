import SwiftData
import SwiftUI

struct ExpandableImageView: View {
    let image: NSImage
    var maxSize: CGSize? = CGSize(width: 180, height: 120)

    @State private var isExpanded: Bool = false
    @State private var isHovering: Bool = false

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Image(nsImage: image)
                .resizable()
                .interpolation(.high)
                .scaledToFit()
                .frame(
                    maxWidth: maxSize?.width ?? image.size.width,
                    maxHeight: maxSize?.height ?? image.size.height
                )
                .onTapGesture { isExpanded = true }
                .onHover { hovering in
                    isHovering = hovering
                }
                .contextMenu {
                    Button("Copy") {
                        copyToPasteboard(image)
                    }
                }
                .overlay(alignment: .topTrailing) {
                    if isHovering {
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
        }
        .sheet(isPresented: $isExpanded) {
            ExpandedImageView(image: image, isExpanded: $isExpanded)
        }
    }
}

struct ExpandedImageView: View {
    let image: NSImage
    @Binding var isExpanded: Bool

    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0

    var body: some View {
        let fittedSize = fittedImageSize()
        return VStack(spacing: 16) {
            ScrollView([.horizontal, .vertical]) {
                Image(nsImage: image)
                    .resizable()
                    .interpolation(.high)
                    .scaledToFit()
                    .frame(width: fittedSize.width * scale, height: fittedSize.height * scale)
                    .animation(.none, value: scale) // prevent implicit animations during pinch
                    .gesture(
                        MagnificationGesture()
                            .onChanged { value in
                                scale = min(max(lastScale * value, 0.5), 6.0)
                            }
                            .onEnded { _ in
                                lastScale = scale
                            }
                    )
                    .contextMenu {
                        Button("Copy") {
                            copyToPasteboard(image)
                        }
                    }
            }
            .frame(width: fittedSize.width, height: fittedSize.height)
            .padding()

            HStack {
                Spacer()
                Button {
                    isExpanded = false
                } label: {
                    Label("Close", systemImage: "xmark")
                }
                .buttonStyle(.borderedProminent)
                Spacer()
            }
            .padding(.bottom)
        }
        .presentationSizing(.fitted)
    }

    private func fittedImageSize() -> CGSize {
        let screen = NSScreen.main?.visibleFrame.size ?? CGSize(width: 1440, height: 900)
        let maxW = screen.width * 0.85
        let maxH = screen.height * 0.85
        let imgSize = image.size
        guard imgSize.width > 0, imgSize.height > 0 else {
            return CGSize(width: maxW, height: maxH)
        }
        let ratio = min(maxW / imgSize.width, maxH / imgSize.height)
        return CGSize(width: imgSize.width * ratio, height: imgSize.height * ratio)
    }
}

func copyToPasteboard(_ image: NSImage) {
    let pasteboard = NSPasteboard.general
    pasteboard.clearContents()
    pasteboard.writeObjects([image])
}
