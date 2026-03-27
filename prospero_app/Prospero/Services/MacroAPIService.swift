//
//  MacroAPIService.swift
//  Prospero
//
//  Created on $(date)
//

import Foundation

class MacroAPIService {
    static let shared = MacroAPIService()
    
    private let baseURL = "https://nocc6zkfqkzt46smrf4sekau7i0efrze.lambda-url.ap-northeast-2.on.aws"
    
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
}



