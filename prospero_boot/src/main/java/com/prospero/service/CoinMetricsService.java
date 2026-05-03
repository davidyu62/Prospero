package com.prospero.service;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestTemplate;
import org.springframework.web.util.UriComponentsBuilder;

import java.time.LocalDate;
import java.time.format.DateTimeFormatter;

@Service
@Slf4j
public class CoinMetricsService {

    private static final String COIN_METRICS_URL = "https://community-api.coinmetrics.io/v4/timeseries/asset-metrics";
    private final RestTemplate restTemplate = new RestTemplate();
    private final ObjectMapper objectMapper = new ObjectMapper();

    public Double getMvrv(String date) {
        return getMetric(date, "CapMVRVCur", Double.class);
    }

    public Long getActiveAddresses(String date) {
        Double value = getMetric(date, "AdrActCnt", Double.class);
        return value != null ? value.longValue() : null;
    }

    private <T> T getMetric(String date, String metric, Class<T> type) {
        try {
            LocalDate targetDate = parseDate(date);
            LocalDate startDate = targetDate.minusDays(3);
            LocalDate endDate = targetDate;

            DateTimeFormatter formatter = DateTimeFormatter.ISO_DATE;
            String url = UriComponentsBuilder.fromHttpUrl(COIN_METRICS_URL)
                    .queryParam("assets", "btc")
                    .queryParam("metrics", metric)
                    .queryParam("frequency", "1d")
                    .queryParam("start_time", startDate.format(formatter))
                    .queryParam("end_time", endDate.format(formatter))
                    .queryParam("page_size", "5")
                    .build()
                    .toUriString();

            log.info("CoinMetrics {} 조회: {}", metric, url);

            String response = restTemplate.getForObject(url, String.class);
            JsonNode jsonResponse = objectMapper.readTree(response);

            JsonNode dataArray = jsonResponse.get("data");
            if (dataArray.isArray() && dataArray.size() > 0) {
                // 역순으로 iterate하여 최신 non-null 값 찾기
                for (int i = dataArray.size() - 1; i >= 0; i--) {
                    JsonNode item = dataArray.get(i);
                    JsonNode metricValue = item.get(metric);

                    if (metricValue != null && !metricValue.isNull() && metricValue.asText().equals(".") == false) {
                        if (type == Double.class) {
                            return type.cast(Double.parseDouble(metricValue.asText()));
                        }
                    }
                }
            }

            log.warn("CoinMetrics {} 데이터를 찾을 수 없음", metric);
            return null;
        } catch (Exception e) {
            log.error("CoinMetrics {} 조회 중 오류 발생", metric, e);
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
