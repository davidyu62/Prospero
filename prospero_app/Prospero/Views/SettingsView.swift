//
//  SettingsView.swift
//  Prospero
//
//  Created on $(date)
//

import SwiftUI
import UIKit

struct SettingsView: View {
    @EnvironmentObject var theme: ThemeManager
    @AppStorage("selectedLanguage") private var selectedLanguage: String = "ENG"
    @State private var showLanguageSelection = false
    @State private var showThemeSelection = false
    
    private var localization: Localization {
        Localization.shared.language = selectedLanguage
        return Localization.shared
    }
    
    private var themeDisplayValue: String {
        selectedLanguage == "KOR" ? theme.theme.displayNameKOR : theme.theme.displayName
    }
    
    var body: some View {
        ZStack {
            theme.appBackground
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 0) {
                    // Header
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(spacing: 12) {
                            Text("Prospero")
                                .font(.custom("Snell Roundhand", size: 28))
                                .foregroundColor(theme.primaryText)

                            Spacer()
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    .padding(.bottom, 20)

                    // 헤더 아래 구분선
                    Rectangle()
                        .fill(Color.white.opacity(0.08))
                        .frame(height: 0.5)
                        .padding(.bottom, 20)

                    VStack(spacing: 0) {
                        // Theme Section
                        SettingsSection(theme: theme) {
                            SettingsRow(theme: theme, icon: "paintbrush.fill", title: localization.settings("Theme"), value: themeDisplayValue) {
                                showThemeSelection = true
                            }
                        }
                        
                        // Language Section
                        SettingsSection(theme: theme) {
                            SettingsRow(theme: theme, icon: "globe", title: localization.settings("Language"), value: localization.settings(selectedLanguage)) {
                                showLanguageSelection = true
                            }
                        }
                    }
                    .padding(.top, 20)
                    .padding(.bottom, 100)
                }
            }
        }
        .sheet(isPresented: $showLanguageSelection) {
            LanguageSelectionView(selectedLanguage: $selectedLanguage)
        }
        .sheet(isPresented: $showThemeSelection) {
            ThemeSelectionView(theme: theme)
        }
    }
}

// MARK: - Settings Section
struct SettingsSection<Content: View>: View {
    @ObservedObject var theme: ThemeManager
    let content: Content
    
    init(theme: ThemeManager, @ViewBuilder content: () -> Content) {
        self.theme = theme
        self.content = content()
    }
    
    var body: some View {
        VStack(spacing: 0) {
            content
        }
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(theme.cardBackground)
        )
        .padding(.horizontal, 20)
        .padding(.bottom, 20)
    }
}

// MARK: - Settings Row
struct SettingsRow: View {
    @ObservedObject var theme: ThemeManager
    let icon: String
    let title: String
    let value: String?
    let action: () -> Void
    
    init(theme: ThemeManager, icon: String, title: String, value: String? = nil, action: @escaping () -> Void) {
        self.theme = theme
        self.icon = icon
        self.title = title
        self.value = value
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(theme.secondaryText)
                    .frame(width: 24)
                
                Text(title)
                    .font(.system(size: 16))
                    .foregroundColor(theme.primaryText)
                
                Spacer()
                
                if let value = value {
                    Text(value)
                        .font(.system(size: 16))
                        .foregroundColor(theme.secondaryText)
                }
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(theme.quaternaryText)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
    }
}

// MARK: - Theme Selection View
struct ThemeSelectionView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var theme: ThemeManager
    @AppStorage("selectedLanguage") private var selectedLanguage: String = "ENG"
    
    private var localization: Localization {
        Localization.shared.language = selectedLanguage
        return Localization.shared
    }
    
    var body: some View {
        NavigationView {
            List {
                ThemeOptionRow(
                    themeOption: .dark,
                    displayName: localization.settings("Dark"),
                    isSelected: theme.theme == .dark
                ) {
                    theme.theme = .dark
                    dismiss()
                }
                
                ThemeOptionRow(
                    themeOption: .light,
                    displayName: localization.settings("Light"),
                    isSelected: theme.theme == .light
                ) {
                    theme.theme = .light
                    dismiss()
                }
            }
            .navigationTitle(localization.settings("Theme"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(localization.common("Done")) {
                        dismiss()
                    }
                    .foregroundColor(.blue)
                }
            }
        }
    }
}

// MARK: - Theme Option Row
struct ThemeOptionRow: View {
    let themeOption: AppTheme
    let displayName: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Text(displayName)
                    .font(.system(size: 16))
                    .foregroundColor(.primary)
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.blue)
                }
            }
        }
    }
}

// MARK: - Language Selection View
struct LanguageSelectionView: View {
    @Environment(\.dismiss) var dismiss
    @Binding var selectedLanguage: String
    
    private var localization: Localization {
        Localization.shared.language = selectedLanguage
        return Localization.shared
    }
    
    var body: some View {
        NavigationView {
            List {
                LanguageOptionRow(
                    language: localization.settings("ENG"),
                    languageCode: "ENG",
                    isSelected: selectedLanguage == "ENG",
                    action: {
                        selectedLanguage = "ENG"
                        dismiss()
                    }
                )
                
                LanguageOptionRow(
                    language: localization.settings("KOR"),
                    languageCode: "KOR",
                    isSelected: selectedLanguage == "KOR",
                    action: {
                        selectedLanguage = "KOR"
                        dismiss()
                    }
                )
            }
            .navigationTitle(localization.settings("Language"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(localization.common("Done")) {
                        dismiss()
                    }
                    .foregroundColor(.blue)
                }
            }
        }
    }
}

// MARK: - Language Option Row
struct LanguageOptionRow: View {
    let language: String
    let languageCode: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Text(language)
                    .font(.system(size: 16))
                    .foregroundColor(.primary)
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.blue)
                }
            }
        }
    }
}

#Preview {
    SettingsView()
        .environmentObject(ThemeManager.shared)
}

