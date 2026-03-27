//
//  ProsperoApp.swift
//  Prospero
//
//  Created by 78142 on 1/20/26.
//

import SwiftUI
import GoogleMobileAds

@main
struct ProsperoApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @State private var showSplash = true

    init() {
        // Google AdMob SDK 초기화 (광고 로드 전 필수)
        GADMobileAds.sharedInstance().start { _ in
            Task { @MainActor in
                RewardedAdManager.shared.loadAd()
            }
        }
    }

    var body: some Scene {
        WindowGroup {
            ZStack {
                CryptoDashboardView()
                    .environmentObject(ThemeManager.shared)

                if showSplash {
                    SplashScreenView(isVisible: $showSplash)
                        .zIndex(1)
                }
            }
            .task {
                try? await Task.sleep(nanoseconds: 3_000_000_000)
                showSplash = false
            }
        }
    }
}
