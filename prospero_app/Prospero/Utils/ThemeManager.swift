//
//  ThemeManager.swift
//  Prospero
//
//  앱 테마 관리 - Dark / Light
//

import SwiftUI
import Combine

enum AppTheme: String, CaseIterable {
    case dark = "dark"
    case light = "light"
    
    var displayName: String {
        switch self {
        case .dark: return "Dark"
        case .light: return "Light"
        }
    }
    
    var displayNameKOR: String {
        switch self {
        case .dark: return "다크"
        case .light: return "라이트"
        }
    }
}

@MainActor
final class ThemeManager: ObservableObject {
    static let shared = ThemeManager()

    @AppStorage("appTheme") var theme: AppTheme = .dark {
        didSet { objectWillChange.send() }
    }

    private init() {}

    // MARK: - Background Colors
    var appBackground: Color {
        switch theme {
        case .dark: return .darkBackground
        case .light: return .lightBackground
        }
    }

    var cardBackground: Color {
        switch theme {
        case .dark: return .darkCardBackground
        case .light: return .lightCardBackground
        }
    }

    var cardIconBackground: Color {
        switch theme {
        case .dark: return .darkAccentBackground
        case .light: return .lightAccentBackground
        }
    }

    // MARK: - Text Colors
    var primaryText: Color {
        switch theme {
        case .dark: return .darkPrimaryText
        case .light: return .lightPrimaryText
        }
    }

    var secondaryText: Color {
        switch theme {
        case .dark: return .darkSecondaryText
        case .light: return .lightSecondaryText
        }
    }

    var tertiaryText: Color {
        switch theme {
        case .dark: return .darkTertiaryText
        case .light: return .lightTertiaryText
        }
    }

    var quaternaryText: Color {
        switch theme {
        case .dark: return .darkDisabledText
        case .light: return .lightDisabledText
        }
    }

    /// Fear & Greed indicator dot, tab bar unselected - needs contrast on both themes
    var indicatorColor: Color {
        switch theme {
        case .dark: return .white
        case .light: return .white
        }
    }

    /// Tab bar / bottom nav background
    var tabBarBackground: Color {
        switch theme {
        case .dark: return .clear
        case .light: return .lightCardBackground
        }
    }

    // MARK: - Gradient
    var primaryGradient: LinearGradient {
        switch theme {
        case .dark: return .darkPrimaryGradient
        case .light: return .lightPrimaryGradient
        }
    }

    // MARK: - Component Styling
    var cardShadow: Color {
        switch theme {
        case .dark: return .black.opacity(0.15)
        case .light: return .black.opacity(0.08)
        }
    }

    var cardBorderColor: Color {
        switch theme {
        case .dark: return Color.white.opacity(0.1)
        case .light: return Color.black.opacity(0.05)
        }
    }

    /// 카드 코너 반지름
    var cardCornerRadius: CGFloat { 16 }

    /// 버튼 코너 반지름
    var buttonCornerRadius: CGFloat { 12 }

    /// 기본 간격 (16px)
    var standardSpacing: CGFloat { 16 }
}
