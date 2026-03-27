//
//  AIAnalysisAPIService.swift
//  Prospero
//
//  AI 투자 분석 API 호출 서비스

import Foundation

class AIAnalysisAPIService {
    static let shared = AIAnalysisAPIService()

    private let baseURL = "https://nocc6zkfqkzt46smrf4sekau7i0efrze.lambda-url.ap-northeast-2.on.aws"

    private init() {}

    func fetchAIAnalysis(for date: String) async throws -> (analysis: AIAnalysisResponse, crypto: CryptoDataItem?, macro: MacroDataItem?) {
        // 1. AI 분석 데이터 조회
        let aiAnalysis = try await fetchAIAnalysisOnly(for: date)

        // 2. Crypto 데이터 조회 (지표분석용 원시값)
        var cryptoData: CryptoDataItem? = nil
        do {
            let cryptoResponse = try await CryptoAPIService.shared.fetchCryptoDataWithPrevious(date: date)
            cryptoData = cryptoResponse.data.requestDate
        } catch {
            print("⚠️  Crypto 데이터 조회 실패 (지표분석 표시 불가): \(error)")
        }

        // 3. Macro 데이터 조회 (지표분석용 원시값)
        var macroData: MacroDataItem? = nil
        do {
            let macroResponse = try await MacroAPIService.shared.fetchMacroDataWithPrevious(date: date)
            macroData = macroResponse.data.requestDate
        } catch {
            print("⚠️  Macro 데이터 조회 실패 (지표분석 표시 불가): \(error)")
        }

        return (analysis: aiAnalysis, crypto: cryptoData, macro: macroData)
    }

    private func fetchAIAnalysisOnly(for date: String) async throws -> AIAnalysisResponse {
        let urlString = "\(baseURL)/api/ai-analysis/date?date=\(date)"
        print("🌐 AI Analysis API URL: \(urlString)")

        guard let url = URL(string: urlString) else {
            print("❌ 잘못된 URL: \(urlString)")
            throw AIAnalysisAPIError.invalidURL
        }

        print("📡 HTTP 요청 시작...")
        let (data, response) = try await URLSession.shared.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse else {
            print("❌ HTTP 응답이 아닙니다")
            throw AIAnalysisAPIError.invalidResponse
        }

        print("📥 HTTP 상태 코드: \(httpResponse.statusCode)")

        guard httpResponse.statusCode == 200 else {
            print("❌ HTTP 에러: \(httpResponse.statusCode)")
            if let responseString = String(data: data, encoding: .utf8) {
                print("   응답 본문: \(responseString)")
            }
            throw AIAnalysisAPIError.invalidResponse
        }

        print("📦 응답 데이터 크기: \(data.count) bytes")

        let decoder = JSONDecoder()
        do {
            let decoded = try decoder.decode(AIAnalysisResponse.self, from: data)
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

enum AIAnalysisAPIError: Error {
    case invalidURL
    case invalidResponse
    case decodingError
}

