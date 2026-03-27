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
}

enum APIError: Error {
    case invalidURL
    case invalidResponse
    case decodingError
}

