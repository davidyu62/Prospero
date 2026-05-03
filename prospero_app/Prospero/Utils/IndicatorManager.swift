import Foundation

struct IndicatorInfo: Codable {
    let id: String
    let category: String
    let englishName: String
    let koreanName: String
    let englishSubtitle: String
    let koreanSubtitle: String
    let englishExplanation: String?
    let koreanExplanation: String?
}

struct IndicatorMetadata: Codable {
    let indicators: [IndicatorInfo]
}

class IndicatorManager {
    static let shared = IndicatorManager()

    private var metadata: IndicatorMetadata?
    private var indicatorMap: [String: IndicatorInfo] = [:]

    private init() {
        loadMetadata()
    }

    private func loadMetadata() {
        guard let url = Bundle.main.url(forResource: "IndicatorMetadata", withExtension: "json") else {
            print("[ERROR] IndicatorMetadata.json not found")
            return
        }

        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            metadata = try decoder.decode(IndicatorMetadata.self, from: data)

            if let indicators = metadata?.indicators {
                for indicator in indicators {
                    indicatorMap[indicator.id] = indicator
                }
                print("[INFO] Loaded \(indicatorMap.count) indicators")
            }
        } catch {
            print("[ERROR] Failed to load IndicatorMetadata: \(error)")
        }
    }

    func getIndicator(_ id: String) -> IndicatorInfo? {
        return indicatorMap[id]
    }

    func getName(_ id: String, language: String = "ENG") -> String {
        guard let indicator = indicatorMap[id] else {
            return id
        }
        return language == "KOR" ? indicator.koreanName : indicator.englishName
    }

    func getSubtitle(_ id: String, language: String = "ENG") -> String {
        guard let indicator = indicatorMap[id] else {
            return ""
        }
        return language == "KOR" ? indicator.koreanSubtitle : indicator.englishSubtitle
    }

    func getExplanation(_ id: String, language: String = "ENG") -> String {
        guard let indicator = indicatorMap[id] else {
            return ""
        }
        return language == "KOR" ? (indicator.koreanExplanation ?? "") : (indicator.englishExplanation ?? "")
    }

    func getCryptoIndicators() -> [IndicatorInfo] {
        return metadata?.indicators.filter { $0.category == "crypto" } ?? []
    }

    func getMacroIndicators() -> [IndicatorInfo] {
        return metadata?.indicators.filter { $0.category == "macro" } ?? []
    }

    func getAllIndicators() -> [IndicatorInfo] {
        return metadata?.indicators ?? []
    }
}
