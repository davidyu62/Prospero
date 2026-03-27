//
//  AppIconPreviewView.swift
//  Prospero
//
//  Created on $(date)
//

import SwiftUI

struct AppIconPreviewView: View {
    var body: some View {
        ZStack {
            // Background for preview
            Color.gray.opacity(0.2)
                .ignoresSafeArea()
            
            VStack(spacing: 40) {
                Text("App Icon Preview")
                    .font(.system(size: 24, weight: .bold))
                    .padding(.top, 40)
                
                // Small size (for UI)
                VStack(spacing: 8) {
                    Text("Small (44pt)")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondary)
                    AppIconView(size: 44)
                }
                
                // Medium size
                VStack(spacing: 8) {
                    Text("Medium (120pt)")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondary)
                    AppIconView(size: 120)
                }
                
                // Large size (actual app icon size)
                VStack(spacing: 8) {
                    Text("Large (240pt)")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondary)
                    AppIconView(size: 240)
                }
                
                // Full size (1024pt - for actual app icon)
                VStack(spacing: 8) {
                    Text("Full Size (1024pt)")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondary)
                    Text("이 크기로 스크린샷을 찍어서\n앱 아이콘으로 사용하세요")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                    AppIconView(size: 400) // Preview에서는 400pt로 표시
                }
                
                Spacer()
            }
            .padding()
        }
    }
}

#Preview {
    AppIconPreviewView()
}


