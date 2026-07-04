import SwiftUI

struct FullScreenAdView: View {
    @Binding var isPresented: Bool

    var body: some View {
        ZStack {
            // 배경 (검은색 반투명)
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.black.opacity(0.8),
                    Color.black.opacity(0.9)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 24) {
                Spacer()

                // 광고 아이콘
                VStack(spacing: 16) {
                    Image(systemName: "megaphone.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.white)

                    Text("Special Offer!")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.white)

                    Text("Discover exclusive investment insights with Prospero Pro")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)
                }

                Spacer()

                // 광고 버튼들
                VStack(spacing: 12) {
                    // Learn More 버튼
                    Button(action: {
                        // 실제 광고 액션 처리
                        print("광고 클릭")
                        isPresented = false
                    }) {
                        Text("Learn More")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(Color.white)
                            .cornerRadius(12)
                    }

                    // 닫기 버튼
                    Button(action: {
                        isPresented = false
                    }) {
                        Text("Close")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(Color.white.opacity(0.2))
                            .cornerRadius(12)
                    }
                }
                .padding(.horizontal, 20)

                Spacer()
                    .frame(height: 40)
            }
            .padding(.vertical, 40)
        }
    }
}

#Preview {
    @State var isPresented = true
    return FullScreenAdView(isPresented: $isPresented)
}
