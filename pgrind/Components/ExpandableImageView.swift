import SwiftUI
import SwiftData

struct ExpandableImageView: View {
    let image: NSImage
    
    @State private var isExpanded: Bool = false
    @State private var isHovering: Bool = false
    
    private func copyToPasteboard(_ image: NSImage) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.writeObjects([image])
    }
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            Image(nsImage: image)
                .resizable()
                .interpolation(.high)
                .scaledToFit()
                .frame(maxWidth: image.size.width, maxHeight: image.size.height)
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
            VStack(spacing: 16) {
                ScrollView {
                    Image(nsImage: image)
                        .resizable()
                        .interpolation(.high)
                        .scaledToFit()
                        .frame(maxWidth: image.size.width, maxHeight: image.size.height)
                        .contextMenu {
                            Button("Copy") {
                                copyToPasteboard(image)
                            }
                        }
                }
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
            .presentationSizing(.automatic)
        }
    }
}
