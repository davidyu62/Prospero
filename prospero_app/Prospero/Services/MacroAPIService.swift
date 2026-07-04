//
//  MacroAPIService.swift
//  Prospero
//
//  Created on $(date)
//

import Foundation

class MacroAPIService {
    static let shared = MacroAPIService()
    
    private let baseURL = "https://n84fir7sq6.execute-api.ap-northeast-2.amazonaws.com/prod"
    
    private init() {}
    
    func fetchMacroDataWithPrevious(date: String) async throws -> MacroAPIResponse {
        let urlString = "\(baseURL)/api/macro-data/db/date-with-previous?date=\(date)"
        print("🌐 Macro API URL: \(urlString)")
        
        guard let url = URL(string: urlString) else {
            print("❌ 잘못된 URL: \(urlString)")
            throw APIError.invalidURL
        }
        
        print("📡 Macro HTTP 요청 시작...")
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            print("❌ Macro HTTP 응답이 아닙니다")
            throw APIError.invalidResponse
        }
        
        print("📥 Macro HTTP 상태 코드: \(httpResponse.statusCode)")
        
        guard httpResponse.statusCode == 200 else {
            print("❌ Macro HTTP 에러: \(httpResponse.statusCode)")
            if let responseString = String(data: data, encoding: .utf8) {
                print("   응답 본문: \(responseString)")
            }
            throw APIError.invalidResponse
        }
        
        print("📦 Macro 응답 데이터 크기: \(data.count) bytes")
        if let responseString = String(data: data, encoding: .utf8) {
            print("📄 Macro 응답 본문: \(responseString.prefix(500))...")
        }
        
        let decoder = JSONDecoder()
        do {
            let decoded = try decoder.decode(MacroAPIResponse.self, from: data)
            print("✅ Macro JSON 디코딩 성공")
            return decoded
        } catch {
            print("❌ Macro JSON 디코딩 실패: \(error)")
            if let decodingError = error as? DecodingError {
                switch decodingError {
                case .keyNotFound(let key, let context):
                    print("   키 누락: \(key.stringValue), 컨텍스트: \(context)")
                case .typeMismatch(let type, let context):
                    print("   타입 불일치: \(type), 컨텍스트: \(context)")
                case .valueNotFound(let type, let context):
                    print("   값 누락: \(type), 컨텍스트: \(context)")
                case .dataCorrupted(let context):
                    print("   데이터 손상: \(context)")
                @unknown default:
                    print("   알 수 없는 디코딩 에러")
                }
            }
            throw error
        }
    }

    /// 30일(기본) 범위 데이터 조회. 실패 시 호출부에서 스텁으로 폴백한다.
    /// 매크로 범위 조회.
    /// - months 지정 시: 최근 months개월의 '각 달 1일' 데이터(월 단위 그래프용).
    /// - 아니면: 과거 days일 일 단위.
    func fetchMacroRange(date: String, days: Int = 30, months: Int? = nil) async throws -> MacroRangeResponse {
        let query: String
        if let months = months {
            query = "months=\(months)"
        } else {
            query = "days=\(days)"
        }
        let urlString = "\(baseURL)/api/macro-data/db/range?date=\(date)&\(query)"
        print("🌐 Macro 범위 API URL: \(urlString)")

        guard let url = URL(string: urlString) else {
            throw APIError.invalidURL
        }

        let (data, response) = try await URLSession.shared.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            let code = (response as? HTTPURLResponse)?.statusCode ?? -1
            print("❌ Macro 범위 API 실패: HTTP \(code)")
            throw APIError.invalidResponse
        }

        return try JSONDecoder().decode(MacroRangeResponse.self, from: data)
    }
}



