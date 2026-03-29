//
//  SplashScreenView.swift
//  Prospero
//
//  Created by 78142 on 3/25/26.
//

import SwiftUI

struct SplashScreenView: View {
    @Binding var isVisible: Bool
    @State private var displayedText: String = ""
    @State private var shownIndices: Set<Int> = []
    @State private var showCursor: Bool = false

    var body: some View {
        ZStack {
            Color(red: 0.05, green: 0.05, blue: 0.07)
                .ignoresSafeArea()

            VStack(spacing: 24) {
                HStack(spacing: 0) {
                    // 각 글자를 개별적으로 표시 (글자가 그려지는 효과)
                    ForEach(Array(displayedText.enumerated()), id: \.offset) { index, char in
                        Text(String(char))
                            .font(.custom("Snell Roundhand", size: 72))
                            .foregroundColor(.white)
                            .opacity(shownIndices.contains(index) ? 1 : 0)
                            .offset(y: shownIndices.contains(index) ? 0 : 15)  // 아래에서 위로
                            .scaleEffect(shownIndices.contains(index) ? 1 : 0.7, anchor: .center)
                    }

                    // 타이핑 커서
                    if !displayedText.isEmpty {
                        Rectangle()
                            .fill(Color.white)
                            .frame(width: 2, height: 80)
                            .opacity(showCursor ? 1 : 0)
                            .animation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true), value: showCursor)
                    }
                }
                .frame(height: 90, alignment: .center)
            }
        }
        .opacity(isVisible ? 1 : 0)
        .animation(.easeOut(duration: 0.5), value: isVisible)
        .task {
            let fullText = "Prospero"

            // 타이핑 시작 전 0.1초 대기
            try? await Task.sleep(nanoseconds: 100_000_000)

            // 글자 하나씩 추가 (각 글자가 나타나는 효과)
            for index in 0..<fullText.count {
                let char = Array(fullText)[index]
                displayedText.append(char)

                // 글자가 아래에서 위로 올라오며 나타나는 효과 (0.3초)
                withAnimation(.easeOut(duration: 0.3)) {
                    shownIndices.insert(index)
                }

                // 다음 글자 출현까지 0.35초 대기
                try? await Task.sleep(nanoseconds: 350_000_000)
            }

            // 타이핑 완료 후 커서 깜박임 시작
            showCursor = true
        }
    }
}

#Preview {
    SplashScreenView(isVisible: .constant(true))
}
