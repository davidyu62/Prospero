//
//  SplashScreenView.swift
//  Prospero
//
//  Created by 78142 on 3/25/26.
//

import SwiftUI

struct SplashScreenView: View {
    @Binding var isVisible: Bool

    var body: some View {
        ZStack {
            Color(red: 0.05, green: 0.05, blue: 0.07)
                .ignoresSafeArea()

            VStack(spacing: 24) {
                AppIconView(size: 120)
                Text("Prospero")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.white)
            }
        }
        .opacity(isVisible ? 1 : 0)
        .animation(.easeOut(duration: 0.5), value: isVisible)
    }
}

#Preview {
    SplashScreenView(isVisible: .constant(true))
}
