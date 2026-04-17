//
//  AppColors.swift
//  Prospero
//
//  앱 전역 색상 팔레트 - DESIGN_SYSTEM.md 기반
//

import SwiftUI

// MARK: - Dark Theme Colors
extension Color {
    // 다크 테마 배경
    static let darkBackground = Color(red: 12/255, green: 16/255, blue: 28/255)  // #0C101C
    static let darkCardBackground = Color(red: 18/255, green: 23/255, blue: 37/255)  // #121725
    static let darkAccentBackground = Color(red: 24/255, green: 29/255, blue: 43/255)  // #181D2B

    // 라이트 테마 배경
    static let lightBackground = Color(red: 248/255, green: 250/255, blue: 252/255)  // #F8FAFC
    static let lightCardBackground = Color.white
    static let lightAccentBackground = Color(red: 241/255, green: 245/255, blue: 249/255)  // #F1F5F9

    // 다크 테마 텍스트
    static let darkPrimaryText = Color.white
    static let darkSecondaryText = Color(red: 160/255, green: 174/255, blue: 192/255)  // #A0AEC0
    static let darkTertiaryText = Color(red: 113/255, green: 128/255, blue: 150/255)  // #718096
    static let darkDisabledText = Color(red: 74/255, green: 85/255, blue: 104/255)  // #4A5568

    // 라이트 테마 텍스트
    static let lightPrimaryText = Color(red: 15/255, green: 23/255, blue: 42/255)  // #0F172A
    static let lightSecondaryText = Color(red: 71/255, green: 85/255, blue: 105/255)  // #475569
    static let lightTertiaryText = Color(red: 148/255, green: 163/255, blue: 184/255)  // #94A3B8
    static let lightDisabledText = Color(red: 203/255, green: 213/255, blue: 225/255)  // #CBD5E1

    // 상태 색상
    static let successColor = Color(red: 16/255, green: 185/255, blue: 129/255)  // #10B981
    static let warningColor = Color(red: 245/255, green: 158/255, blue: 11/255)  // #F59E0B
    static let dangerColor = Color(red: 239/255, green: 68/255, blue: 68/255)  // #EF4444
    static let accentColor = Color(red: 255/255, green: 165/255, blue: 0/255)  // #FFA500 (다크)
    static let accentColorLight = Color(red: 249/255, green: 115/255, blue: 22/255)  // #F97316 (라이트)
}

// MARK: - Gradients
extension LinearGradient {
    /// 다크 테마 Primary Gradient
    static let darkPrimaryGradient = LinearGradient(
        gradient: Gradient(colors: [
            Color(red: 0, green: 217/255, blue: 255/255),  // #00D9FF
            Color(red: 124/255, green: 58/255, blue: 237/255)  // #7C3AED
        ]),
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    /// 라이트 테마 Primary Gradient
    static let lightPrimaryGradient = LinearGradient(
        gradient: Gradient(colors: [
            Color(red: 14/255, green: 165/255, blue: 233/255),  // #0EA5E9
            Color(red: 139/255, green: 92/255, blue: 246/255)  // #8B5CF6
        ]),
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}
