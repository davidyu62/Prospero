import Foundation
import SwiftUI
import Combine
import GoogleMobileAds

class AdManager: NSObject, ObservableObject, GADFullScreenContentDelegate {
    static let shared = AdManager()

    @Published var interstitialAd: GADInterstitialAd?
    private let lastAdShowTimeKey = "lastAdShowTime_AITab"
    private let adShowInterval: TimeInterval = 3600 // 1시간(초 단위)

    override init() {
        super.init()
        GADMobileAds.sharedInstance().start()
    }

    /// 광고를 표시할 수 있는지 확인 (1시간 경과 체크)
    func canShowAd() -> Bool {
        let lastShowTime = UserDefaults.standard.double(forKey: lastAdShowTimeKey)
        if lastShowTime == 0 {
            // 처음으로 광고를 보여주는 경우
            return true
        }

        let currentTime = Date().timeIntervalSince1970
        let elapsedTime = currentTime - lastShowTime
        return elapsedTime >= adShowInterval
    }

    /// 광고 로드 (AI 탭 진입 시)
    func loadInterstitialAd() {
        // 1시간이 지나지 않았으면 광고 로드하지 않음
        if !canShowAd() {
            print("광고 표시 대기 중 (다음 광고 가능 시간까지 대기)")
            return
        }

        let request = GADRequest()

        // AdMob Interstitial Ad Unit ID로 변경 필요
        // https://admob.google.com에서 앱 등록 후 Unit ID 획득
        GADInterstitialAd.load(
            withAdUnitID: "ca-app-pub-xxxxxxxxxxxxxxxx/yyyyyyyyyyyyyy",
            request: request
        ) { [weak self] ad, error in
            if let error = error {
                print("광고 로드 실패: \(error.localizedDescription)")
                return
            }

            self?.interstitialAd = ad
            ad?.fullScreenContentDelegate = self

            // 광고 로드 성공 후 표시
            DispatchQueue.main.async {
                self?.showInterstitialAd()
            }
        }
    }

    /// 광고 표시
    private func showInterstitialAd() {
        guard let interstitialAd = interstitialAd else {
            print("광고가 로드되지 않았습니다")
            return
        }

        guard let rootViewController = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .flatMap({ $0.windows })
            .first(where: { $0.isKeyWindow })?
            .rootViewController else {
            print("Root View Controller를 찾을 수 없습니다")
            return
        }

        interstitialAd.present(fromRootViewController: rootViewController)
        // 광고 표시 시간 업데이트
        UserDefaults.standard.set(Date().timeIntervalSince1970, forKey: lastAdShowTimeKey)
    }

    // MARK: - GADFullScreenContentDelegate

    func adDidDismissFullScreenContent(_ ad: GADFullScreenPresentingAd) {
        print("광고가 닫혔습니다")
        interstitialAd = nil
    }

    func ad(_ ad: GADFullScreenPresentingAd, didFailToPresentFullScreenContentWithError error: Error) {
        print("광고 표시 실패: \(error.localizedDescription)")
        interstitialAd = nil
    }
}
