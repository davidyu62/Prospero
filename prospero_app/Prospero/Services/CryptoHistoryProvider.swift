//
//  CryptoHistoryProvider.swift
//  Prospero
//
//  지표별 과거 시계열 공급자.
//  - C2 현재: 결정적 스텁(현재값 기준 합성 데이터)을 반환해 UI를 먼저 완성한다.
//  - C4 예정: 백엔드 범위 엔드포인트(/range?from=&to=) 연동으로 이 구현만 교체한다.
//

import Foundation

enum CryptoHistoryProvider {

    /// 지표 key와 현재값으로 days일치 합성 시계열을 생성한다 (오래된 → 최신, 마지막 값 = current).
    /// 동일 입력에 항상 동일 결과(결정적)라 다시 그릴 때 모양이 흔들리지 않는다.
    static func history(for key: IndicatorInterpreter.Key, current: Double, days: Int = 30) -> [Double] {
        let n = max(days, 2)

        // key 문자열 기반 FNV-1a 시드 → 앱 재실행과 무관하게 결정적
        var seed: UInt64 = 1469598103934665603
        for b in key.rawValue.utf8 {
            seed = (seed ^ UInt64(b)) &* 1099511628211
        }
        func rng() -> Double {
            // 선형 합동 생성기 (0.0 ~ 1.0)
            seed = seed &* 6364136223846793005 &+ 1442695040888963407
            return Double((seed >> 33) & 0xFFFFFF) / Double(0xFFFFFF)
        }

        // 변동 폭: 현재값 크기에 비례(최소값 보호). 마지막 값에서 과거로 역산.
        let stepScale = max(abs(current), 1) * 0.02
        var series = [Double](repeating: current, count: n)
        var v = current
        for i in stride(from: n - 2, through: 0, by: -1) {
            let delta = (rng() - 0.5) * 2 * stepScale
            v -= delta
            series[i] = v
        }
        return series
    }
}
