package com.prospero.service;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.prospero.dto.MacroIndicatorResponse;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.web.client.HttpClientErrorException;
import org.springframework.web.client.RestTemplate;
import org.springframework.web.util.UriComponentsBuilder;

import java.time.LocalDate;
import java.time.format.DateTimeFormatter;
import java.util.LinkedHashMap;
import java.util.Map;

@Service
@Slf4j
public class FredService {

    private static final String FRED_API_URL = "https://api.stlouisfed.org/fred/series/observations";

    @Value("${fred.api.key:}")
    private String fredApiKey;

    private final RestTemplate restTemplate = new RestTemplate();
    private final ObjectMapper objectMapper = new ObjectMapper();

    private static final Map<String, String> FRED_SERIES = new LinkedHashMap<>();

    static {
        FRED_SERIES.put("vix", "VIXCLS");
        FRED_SERIES.put("oilPrice", "DCOILWTICO");
        FRED_SERIES.put("yieldSpread", "T10Y2Y");
        FRED_SERIES.put("breakEvenInflation", "T10YIE");
    }

    public MacroIndicatorResponse getMacroIndicators(String date) {
        LocalDate targetDate = parseDate(date);
        DateTimeFormatter formatter = DateTimeFormatter.ISO_DATE;

        MacroIndicatorResponse.MacroIndicatorResponseBuilder builder = MacroIndicatorResponse.builder()
                .date(targetDate.format(DateTimeFormatter.ofPattern("yyyyMMdd")));

        LocalDate startDate = targetDate.minusDays(60);

        for (Map.Entry<String, String> entry : FRED_SERIES.entrySet()) {
            String fieldName = entry.getKey();
            String seriesId = entry.getValue();

            Double value = fetchFredValue(seriesId, startDate, targetDate, formatter);

            switch (fieldName) {
                case "vix":
                    builder.vix(value);
                    break;
                case "goldPrice":
                    builder.goldPrice(value);
                    break;
                case "oilPrice":
                    builder.oilPrice(value);
                    break;
                case "yieldSpread":
                    builder.yieldSpread(value);
                    break;
                case "breakEvenInflation":
                    builder.breakEvenInflation(value);
                    break;
            }
        }

        return builder.build();
    }

    public Double getIndicator(String date, String indicatorName) {
        if (fredApiKey == null || fredApiKey.isEmpty()) {
            log.error("FRED API 키가 설정되지 않았습니다. FRED_API_KEY 환경변수를 설정해주세요.");
            throw new RuntimeException("FRED API 키가 없습니다. 환경변수 FRED_API_KEY를 설정해주세요.");
        }

        LocalDate targetDate = parseDate(date);
        DateTimeFormatter formatter = DateTimeFormatter.ISO_DATE;
        LocalDate startDate = targetDate.minusDays(60);

        String seriesId = FRED_SERIES.get(indicatorName);
        if (seriesId == null) {
            log.warn("지원하지 않는 지표: {}", indicatorName);
            return null;
        }

        return fetchFredValue(seriesId, startDate, targetDate, formatter);
    }

    private Double fetchFredValue(String seriesId, LocalDate startDate, LocalDate endDate, DateTimeFormatter formatter) {
        try {
            String url = UriComponentsBuilder.fromHttpUrl(FRED_API_URL)
                    .queryParam("series_id", seriesId)
                    .queryParam("api_key", fredApiKey)
                    .queryParam("file_type", "json")
                    .queryParam("observation_start", startDate.format(formatter))
                    .queryParam("observation_end", endDate.format(formatter))
                    .queryParam("sort_order", "desc")
                    .queryParam("limit", "1")
                    .build()
                    .toUriString();

            log.debug("FRED {} 조회: {}", seriesId, url);

            String response = restTemplate.getForObject(url, String.class);
            JsonNode jsonResponse = objectMapper.readTree(response);

            // 에러 응답 확인
            if (jsonResponse.has("error_code")) {
                String errorMsg = jsonResponse.has("error_message") ?
                    jsonResponse.get("error_message").asText() : "Unknown error";
                log.error("FRED API 에러 ({}) - {}", seriesId, errorMsg);
                return null;
            }

            JsonNode observations = jsonResponse.get("observations");
            if (observations != null && observations.isArray() && observations.size() > 0) {
                JsonNode firstObs = observations.get(0);
                JsonNode valueNode = firstObs.get("value");

                if (valueNode != null && !valueNode.isNull()) {
                    String valueStr = valueNode.asText();
                    if (!".".equals(valueStr)) {
                        return Double.parseDouble(valueStr);
                    }
                }
            }

            log.warn("FRED {} 데이터를 찾을 수 없음 (조회 범위: {} ~ {})", seriesId, startDate, endDate);
            return null;
        } catch (HttpClientErrorException e) {
            log.error("FRED {} HTTP 에러 ({}): {}", seriesId, e.getStatusCode(), e.getMessage());
            return null;
        } catch (Exception e) {
            log.error("FRED {} 조회 중 오류 발생: {}", seriesId, e.getMessage(), e);
            return null;
        }
    }

    private LocalDate parseDate(String dateStr) {
        if (dateStr == null || dateStr.isEmpty()) {
            return LocalDate.now();
        }
        try {
            DateTimeFormatter formatter = DateTimeFormatter.ofPattern("yyyyMMdd");
            return LocalDate.parse(dateStr, formatter);
        } catch (Exception e) {
            log.warn("날짜 파싱 실패: {}, 오늘 날짜로 설정", dateStr);
            return LocalDate.now();
        }
    }
}
