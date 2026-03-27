//
//  BannerAdView.swift
//  Prospero
//
//  Google AdMob 배너 광고 (테스트 ID 사용)
//

import SwiftUI
import GoogleMobileAds

/// Google AdMob 배너 광고 - SwiftUI 래퍼
/// 테스트 광고 ID 사용 (배포 전 본인 광고 단위 ID로 교체)
struct BannerAdView: View {
    var body: some View {
        AdMobBannerView()
            .frame(height: 50)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
    }
}

/// UIViewRepresentable로 GADBannerView 래핑
private struct AdMobBannerView: UIViewRepresentable {
    func makeUIView(context: Context) -> GADBannerView {
        let bannerView = GADBannerView()
        bannerView.adUnitID = "ca-app-pub-3940256099942544/2435281174" // 테스트 배너 ID
        bannerView.rootViewController = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first { $0.isKeyWindow }?
            .rootViewController
        
        // 화면 너비에 맞는 adaptive banner
        let frame = UIScreen.main.bounds
        bannerView.adSize = GADCurrentOrientationAnchoredAdaptiveBannerAdSizeWithWidth(frame.width)
        bannerView.load(GADRequest())
        bannerView.delegate = context.coordinator
        
        return bannerView
    }
    
    func updateUIView(_ uiView: GADBannerView, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    class Coordinator: NSObject, GADBannerViewDelegate {
        func bannerViewDidReceiveAd(_ bannerView: GADBannerView) {
            print("AdMob: 배너 광고 로드 성공")
        }
        
        func bannerView(_ bannerView: GADBannerView, didFailToReceiveAdWithError error: Error) {
            print("AdMob: 배너 광고 로드 실패 - \(error.localizedDescription)")
        }
    }
}

#Preview {
    ZStack {
        Color.black
        BannerAdView()
    }
}
