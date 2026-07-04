//
//  RewardedAdManager.swift
//  Prospero
//
//  AI 탭 진입 게이트용 리워드(전체 화면) 광고.
//  마지막 광고 노출 후 2시간이 지났을 때만 광고를 표시하고, 광고가 닫히면 진입을 허용한다.
//

import Foundation
import SwiftUI
import GoogleMobileAds

/// 리워드 광고 매니저 - AI 탭 진입 시 2시간 간격으로 광고 노출
@MainActor
final class RewardedAdManager: NSObject {
    static let shared = RewardedAdManager()

    private var rewardedAd: GADRewardedAd?
    // 실제 운영 리워드 광고 ID (AdMob)
    private let adUnitID = "ca-app-pub-4332007596408909/2471272740" // 운영 리워드 광고 ID

    // 광고 노출 간격(2시간) 및 마지막 노출 시각 저장 키
    private let lastAdShowTimeKey = "lastAdShowTime_AITab"
    private let adShowInterval: TimeInterval = 2 * 3600 // 2시간(초 단위)

    // 광고가 닫힌 뒤 실행할 콜백 (예: AI 탭으로 진입)
    private var onFinish: (() -> Void)?

    private override init() {
        super.init()
    }

    /// 광고 미리 로드 (앱 시작 시 및 광고 표시 후 호출)
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

    /// 마지막 광고 노출 후 2시간이 지났는지 여부 (최초 진입이면 true → 광고 표시)
    func shouldShowAd() -> Bool {
        let lastShowTime = UserDefaults.standard.double(forKey: lastAdShowTimeKey)
        if lastShowTime == 0 { return true }
        let elapsed = Date().timeIntervalSince1970 - lastShowTime
        return elapsed >= adShowInterval
    }

    /// 광고 표시 - 광고가 닫히면(시청 완료/중간 닫기 무관) onFinish 호출.
    /// 광고가 아직 로드되지 않았으면 onAdNotReady 호출(없으면 onFinish로 대체해 진입 보장).
    func showAd(onFinish: @escaping () -> Void, onAdNotReady: (() -> Void)? = nil) {
        guard let rewardedAd = rewardedAd else {
            print("AdMob: 리워드 광고가 아직 로드되지 않음")
            (onAdNotReady ?? onFinish)()
            return
        }

        guard let rootVC = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .flatMap({ $0.windows })
            .first(where: { $0.isKeyWindow })?
            .rootViewController else {
            print("AdMob: rootViewController를 찾을 수 없음")
            (onAdNotReady ?? onFinish)()
            return
        }

        // 광고가 닫힐 때 진입시키기 위해 콜백 보관
        self.onFinish = onFinish

        rewardedAd.present(fromRootViewController: rootVC) {
            // 보상 획득(시청 완료) 콜백 - 별도 보상 로직 없음
            print("AdMob: 리워드 광고 시청 완료")
        }

        // 노출 시각 기록(2시간 간격 계산 기준)
        UserDefaults.standard.set(Date().timeIntervalSince1970, forKey: lastAdShowTimeKey)

        self.rewardedAd = nil
        loadAd() // 다음 진입을 위해 재로드
    }
}

extension RewardedAdManager: GADFullScreenContentDelegate {
    /// 광고가 닫히면 보관한 콜백 실행(AI 진입)
    nonisolated func adDidDismissFullScreenContent(_ ad: GADFullScreenPresentingAd) {
        Task { @MainActor in
            let callback = self.onFinish
            self.onFinish = nil
            callback?()
        }
    }

    /// 광고 표시 실패 시에도 사용자가 갇히지 않도록 진입 콜백 실행
    nonisolated func ad(_ ad: GADFullScreenPresentingAd, didFailToPresentFullScreenContentWithError error: Error) {
        Task { @MainActor in
            print("AdMob: 리워드 광고 표시 실패 - \(error.localizedDescription)")
            self.rewardedAd = nil
            let callback = self.onFinish
            self.onFinish = nil
            callback?()
        }
    }
}
