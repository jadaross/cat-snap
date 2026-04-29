import SwiftUI

struct CatPin: View {
    let photoUrl: URL?
    var isSelected: Bool = false

    var body: some View {
        AsyncCatImage(url: photoUrl)
            .frame(width: isSelected ? 52 : 44, height: isSelected ? 52 : 44)
            .clipShape(.circle)
            .overlay(
                Circle().stroke(
                    isSelected ? Color.streetlampYellowDeep : Color.creamSoft,
                    lineWidth: 3
                )
            )
            .shadow(color: Color.ink.opacity(0.25), radius: 4, y: 2)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
    }
}

#Preview {
    HStack(spacing: 16) {
        CatPin(photoUrl: nil)
        CatPin(photoUrl: nil, isSelected: true)
    }
    .padding()
    .background(Color.cream)
}
