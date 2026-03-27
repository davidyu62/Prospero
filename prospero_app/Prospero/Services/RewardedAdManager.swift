//
//  RewardedAdManager.swift
//  Prospero
//
//  AI 탭 진입 시 전체 화면 리워드 광고 (광고 시청 완료 후 AI 페이지 표시)
//

import Foundation
import SwiftUI
import GoogleMobileAds

/// 리워드 광고 매니저 - 광고 시청 완료 시에만 콜백 호출
@MainActor
final class RewardedAdManager: NSObject {
    static let shared = RewardedAdManager()
    
    private var rewardedAd: GADRewardedAd?
    private let adUnitID = "ca-app-pub-3940256099942544/1712485313" // 테스트 리워드 광고 ID
    
    private override init() {
        super.init()
    }
    
    /// 광고 미리 로드 (앱 시작 시 호출 권장)
    func loadAd() {
        Task {
            do {
                rewardedAd = try await GADRewardedAd.load(
                    withAdUnitID: adUnitID,
                    request: GADRequest()
                )
                rewardedAd?.fullScreenContentDelegate = self
                print("AdMob: 리워드 광고 로드 성공")
            } catch {
                print("AdMob: 리워드 광고 로드 실패 - \(error.localizedDescription)")
            }
        }
    }
    
    /// 광고 표시 - 시청 완료 시에만 onReward 호출
    /// 광고 미로드 시 onAdNotReady 호출 (AI 페이지로 이동하지 않음)
    func showAd(onReward: @escaping () -> Void, onAdNotReady: (() -> Void)? = nil) {
        guard let rewardedAd = rewardedAd else {
            print("AdMob: 리워드 광고가 아직 로드되지 않음")
            onAdNotReady?()
            return
        }
        
        guard let rootVC = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .flatMap({ $0.windows })
            .first(where: { $0.isKeyWindow })?
            .rootViewController else {
            print("AdMob: rootViewController를 찾을 수 없음")
            onAdNotReady?()
            return
        }
        
        rewardedAd.present(fromRootViewController: rootVC) {
            print("AdMob: 리워드 광고 시청 완료")
            onReward()
        }
        
        self.rewardedAd = nil
        loadAd() // 다음 진입을 위해 재로드
    }
}

extension RewardedAdManager: GADFullScreenContentDelegate {
    nonisolated func adDidDismissFullScreenContent(_ ad: GADFullScreenPresentingAd) {
        Task { @MainActor in
            rewardedAd = nil
        }
    }
    
    nonisolated func ad(_ ad: GADFullScreenPresentingAd, didFailToPresentFullScreenContentWithError error: Error) {
        Task { @MainActor in
            print("AdMob: 리워드 광고 표시 실패 - \(error.localizedDescription)")
            rewardedAd = nil
        }
    }
}
