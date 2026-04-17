//
//  AIAnalysisAPIService.swift
//  Prospero
//
//  AI 투자 분석 API 호출 서비스

import Foundation

class AIAnalysisAPIService {
    static let shared = AIAnalysisAPIService()

    private let baseURL = "https://n84fir7sq6.execute-api.ap-northeast-2.amazonaws.com/prod"
    private let cacheKeyDate = "ai_cache_date"
    private let cacheKeyData = "ai_cache_data"

    private init() {}

    func fetchAIAnalysis(for date: String) async throws -> (analysis: AIAnalysisResponse, crypto: CryptoDataItem?, macro: MacroDataItem?) {
        // 1. 캐시 확인 - 당일 데이터 있으면 바로 반환
        if let cached = loadCachedAnalysis(for: date) {
            print("✅ 캐시 히트 (\(date))")
            var cryptoData: CryptoDataItem? = nil
            var macroData: MacroDataItem? = nil

            do {
                let cryptoResponse = try await CryptoAPIService.shared.fetchCryptoDataWithPrevious(date: date)
                cryptoData = cryptoResponse.data.requestDate
            } catch {
                print("⚠️  Crypto 데이터 조회 실패: \(error)")
            }

            do {
                let macroResponse = try await MacroAPIService.shared.fetchMacroDataWithPrevious(date: date)
                macroData = macroResponse.data.requestDate
            } catch {
                print("⚠️  Macro 데이터 조회 실패: \(error)")
            }

            return (analysis: cached, crypto: cryptoData, macro: macroData)
        }

        // 2. 캐시 미스 - Lambda 호출
        print("🌐 캐시 미스 - Lambda 호출 (\(date))")
        let aiAnalysis = try await fetchAIAnalysisOnly(for: date)
        cacheAnalysis(aiAnalysis, for: date)

        // 3. Crypto 데이터 조회 (지표분석용 원시값)
        var cryptoData: CryptoDataItem? = nil
        do {
            let cryptoResponse = try await CryptoAPIService.shared.fetchCryptoDataWithPrevious(date: date)
            cryptoData = cryptoResponse.data.requestDate
        } catch {
            print("⚠️  Crypto 데이터 조회 실패 (지표분석 표시 불가): \(error)")
        }

        // 4. Macro 데이터 조회 (지표분석용 원시값)
        var macroData: MacroDataItem? = nil
        do {
            let macroResponse = try await MacroAPIService.shared.fetchMacroDataWithPrevious(date: date)
            macroData = macroResponse.data.requestDate
        } catch {
            print("⚠️  Macro 데이터 조회 실패 (지표분석 표시 불가): \(error)")
        }

        return (analysis: aiAnalysis, crypto: cryptoData, macro: macroData)
    }

    // MARK: - 캐시 메서드

    private func loadCachedAnalysis(for date: String) -> AIAnalysisResponse? {
        return nil // 캐시 비활성화 - 항상 API 호출
//        guard UserDefaults.standard.string(forKey: cacheKeyDate) == date,
//              let data = UserDefaults.standard.data(forKey: cacheKeyData) else {
//            return nil
//        }
//        return try? JSONDecoder().decode(AIAnalysisResponse.self, from: data)
    }

    private func cacheAnalysis(_ analysis: AIAnalysisResponse, for date: String) {
        guard let data = try? JSONEncoder().encode(analysis) else { return }
        UserDefaults.standard.set(date, forKey: cacheKeyDate)
        UserDefaults.standard.set(data, forKey: cacheKeyData)
        print("💾 AI 분석 데이터 캐시 저장 (\(date))")
    }

    // MARK: - API 호출

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

