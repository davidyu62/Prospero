//
//  AppIconGenerator.swift
//  Prospero
//
//  Created on $(date)
//

import SwiftUI

struct AppIconView: View {
    var size: CGFloat = 1024
    
    var body: some View {
        ZStack {
            // Background - Dark gradient
            Circle()
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.1, green: 0.1, blue: 0.12),
                            Color(red: 0.05, green: 0.05, blue: 0.07)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: size, height: size)
                .overlay(
                    Circle()
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.15),
                                    Color.white.opacity(0.05)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: size * 0.01
                        )
                )
                .shadow(color: Color.black.opacity(0.5), radius: size * 0.02, x: 0, y: size * 0.01)
            
            // Icon
            Image(systemName: "sparkles")
                .font(.system(size: size * 0.4, weight: .medium))
                .foregroundStyle(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.9),
                            Color.white.opacity(0.7)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        }
        .frame(width: size, height: size)
    }
}

// MARK: - Preview for App Icon
#Preview("App Icon Preview") {
    ZStack {
        Color.gray.opacity(0.2)
        
        VStack(spacing: 40) {
            // Small size (for UI)
            AppIconView(size: 60)
            
            // Medium size
            AppIconView(size: 120)
            
            // Large size (actual app icon size)
            AppIconView(size: 240)
        }
    }
}


