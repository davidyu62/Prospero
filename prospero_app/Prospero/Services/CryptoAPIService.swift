//
//  CryptoAPIService.swift
//  Prospero
//
//  Created on $(date)
//

import Foundation

class CryptoAPIService {
    static let shared = CryptoAPIService()
    
    private let baseURL = "https://n84fir7sq6.execute-api.ap-northeast-2.amazonaws.com/prod"
    
    private init() {}
    
    func fetchCryptoDataWithPrevious(date: String) async throws -> CryptoAPIResponse {
        let urlString = "\(baseURL)/api/crypto-data/db/date-with-previous?date=\(date)"
        print("🌐 API URL: \(urlString)")
        
        guard let url = URL(string: urlString) else {
            print("❌ 잘못된 URL: \(urlString)")
            throw APIError.invalidURL
        }
        
        print("📡 HTTP 요청 시작...")
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            print("❌ HTTP 응답이 아닙니다")
            throw APIError.invalidResponse
        }
        
        print("📥 HTTP 상태 코드: \(httpResponse.statusCode)")
        
        guard httpResponse.statusCode == 200 else {
            print("❌ HTTP 에러: \(httpResponse.statusCode)")
            if let responseString = String(data: data, encoding: .utf8) {
                print("   응답 본문: \(responseString)")
            }
            throw APIError.invalidResponse
        }
        
        print("📦 응답 데이터 크기: \(data.count) bytes")
        if let responseString = String(data: data, encoding: .utf8) {
            print("📄 응답 본문: \(responseString.prefix(500))...")
        }
        
        let decoder = JSONDecoder()
        do {
            let decoded = try decoder.decode(CryptoAPIResponse.self, from: data)
            print("✅ JSON 디코딩 성공")
            return decoded
        } catch {
            print("❌ JSON 디코딩 실패: \(error)")
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
    /// - Parameters:
    ///   - date: 종료일(yyyyMMdd). 이 날짜 포함 과거 days일.
    ///   - days: 조회 일수 (기본 30)
    func fetchCryptoRange(date: String, days: Int = 30) async throws -> CryptoRangeResponse {
        let urlString = "\(baseURL)/api/crypto-data/db/range?date=\(date)&days=\(days)"
        print("🌐 범위 API URL: \(urlString)")

        guard let url = URL(string: urlString) else {
            throw APIError.invalidURL
        }

        let (data, response) = try await URLSession.shared.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            let code = (response as? HTTPURLResponse)?.statusCode ?? -1
            print("❌ 범위 API 실패: HTTP \(code)")
            throw APIError.invalidResponse
        }

        return try JSONDecoder().decode(CryptoRangeResponse.self, from: data)
    }
}

enum APIError: Error {
    case invalidURL
    case invalidResponse
    case decodingError
}

