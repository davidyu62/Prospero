//
//  DataCard.swift
//  Prospero
//
//  Created on $(date)
//

import SwiftUI

struct DataCard: View {
    let title: String
    let value: String
    let icon: String

    @EnvironmentObject var themeManager: ThemeManager

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(themeManager.secondaryText)
                Spacer()
            }

            Text(title)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(themeManager.tertiaryText)

            Text(value)
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(themeManager.primaryText)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: themeManager.cardCornerRadius)
                .fill(themeManager.cardBackground)
        )
        .overlay(
            RoundedRectangle(cornerRadius: themeManager.cardCornerRadius)
                .stroke(themeManager.cardBorderColor, lineWidth: 1)
        )
        .shadow(
            color: themeManager.cardShadow,
            radius: 12,
            x: 0,
            y: 4
        )
    }
}

#Preview {
    DataCard(title: "Bitcoin", value: "106,350", icon: "bitcoinsign.circle.fill")
        .padding()
        .background(Color.black)
}

