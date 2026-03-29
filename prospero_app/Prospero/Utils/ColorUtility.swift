//
//  ColorUtility.swift
//  Prospero
//
//  Created by 78142 on 3/25/26.
//

import SwiftUI

struct ColorUtility {
    // MARK: - Macro Metric Colors

    /// 실업률 색상 (낮을수록 좋음)
    static func colorForUnemployment(_ value: Double) -> Color {
        if value < 4.0 {
            return .successColor  // 좋음
        } else if value < 5.0 {
            return .warningColor  // 중간
        } else {
            return .dangerColor   // 나쁨
        }
    }

    /// CPI/인플레이션 색상 (2~2.5%가 이상적)
    static func colorForCPI(_ value: Double) -> Color {
        if value >= 2.0 && value <= 2.5 {
            return .successColor  // 좋음
        } else if value > 2.5 && value <= 3.5 {
            return .warningColor  // 중간
        } else {
            return .dangerColor   // 나쁨
        }
    }

    /// 기준금리 색상 (3~4%가 이상적)
    static func colorForInterestRate(_ value: Double) -> Color {
        if value >= 3.0 && value <= 4.5 {
            return .successColor  // 좋음
        } else if value > 4.5 && value <= 5.5 {
            return .warningColor  // 중간
        } else {
            return .dangerColor   // 나쁨
        }
    }

    /// 10Y Treasury 수익률 색상 (4~4.5%가 이상적)
    static func colorForTreasury(_ value: Double) -> Color {
        if value >= 4.0 && value <= 4.5 {
            return .successColor  // 좋음
        } else if value > 4.5 && value <= 5.0 {
            return .warningColor  // 중간
        } else {
            return .dangerColor   // 나쁨
        }
    }

    /// 달러인덱스 색상 (100~104가 이상적)
    static func colorForDollarIndex(_ value: Double) -> Color {
        if value >= 100.0 && value <= 104.0 {
            return .successColor  // 좋음
        } else if value > 104.0 && value <= 108.0 {
            return .warningColor  // 중간
        } else {
            return .dangerColor   // 나쁨
        }
    }

    /// M2 (통화공급량) 색상 - 증가세 선호
    /// value: 전날 대비 변화율 (%)
    static func colorForM2(_ value: Double) -> Color {
        if value > 0 {
            return .successColor  // 증가
        } else if value > -0.1 {
            return .warningColor  // 거의 변화 없음
        } else {
            return .dangerColor   // 감소
        }
    }

    // MARK: - Crypto Change Colors (Gradient)

    /// 변화율에 따른 색상 (Crypto 메트릭)
    static func colorForCryptoChange(_ percentage: Double) -> Color {
        if percentage >= 5.0 {
            return Color(red: 0.20, green: 0.95, blue: 0.40)  // 밝은 초록
        } else if percentage >= 2.0 {
            return .successColor  // 중간 초록
        } else if percentage > 0 {
            return Color(red: 0.40, green: 0.85, blue: 0.50)  // 밝은 초록 (소폭 상승)
        } else if percentage == 0 {
            return Color(red: 0.70, green: 0.70, blue: 0.70)  // 회색 (변화 없음)
        } else if percentage > -2.0 {
            return Color(red: 1.0, green: 0.50, blue: 0.50)   // 밝은 빨강 (소폭 하락)
        } else if percentage >= -5.0 {
            return Color(red: 1.0, green: 0.60, blue: 0.60)   // 중간 빨강
        } else {
            return Color(red: 1.0, green: 0.30, blue: 0.30)   // 어두운 빨강
        }
    }
}
