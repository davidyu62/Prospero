//
//  AppDelegate.swift
//  Prospero
//

import UIKit

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        // 핀치 줌 비활성화: 모든 UIScrollView 인스턴스에서
        UIScrollView.appearance().pinchGestureRecognizer?.isEnabled = false

        return true
    }
}
