import SwiftUI

struct AsyncCatImage: View {
    let url: URL?

    var body: some View {
        Group {
            if let url {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image.resizable().aspectRatio(contentMode: .fill)
                    case .empty:
                        Color.creamDeep.overlay(ProgressView().tint(Color.coral))
                    case .failure:
                        placeholder
                    @unknown default:
                        placeholder
                    }
                }
            } else {
                placeholder
            }
        }
    }

    private var placeholder: some View {
        Color.creamDeep.overlay(
            CatWindowMark(size: 40, showSill: false)
                .opacity(0.6)
        )
    }
}
