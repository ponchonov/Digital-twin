import SwiftUI

struct TypingIndicatorView: View {
    @State private var firstDotScale: CGFloat = 1.0
    @State private var secondDotScale: CGFloat = 1.0
    @State private var thirdDotScale: CGFloat = 1.0
    
    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<3) { index in
                Circle()
                    .fill(Color.gray.opacity(0.6))
                    .frame(width: 8, height: 8)
                    .scaleEffect(getScale(for: index))
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .onAppear {
            animate()
        }
    }
    
    private func getScale(for index: Int) -> CGFloat {
        switch index {
        case 0: return firstDotScale
        case 1: return secondDotScale
        case 2: return thirdDotScale
        default: return 1.0
        }
    }
    
    private func animate() {
        let animation = Animation.easeInOut(duration: 0.5).repeatForever()
        
        withAnimation(animation.delay(0.0)) {
            firstDotScale = 1.4
        }
        withAnimation(animation.delay(0.2)) {
            secondDotScale = 1.4
        }
        withAnimation(animation.delay(0.4)) {
            thirdDotScale = 1.4
        }
    }
}

#Preview {
    TypingIndicatorView()
}