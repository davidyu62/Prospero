package com.prospero.service;

import com.prospero.dto.CryptoNews;
import com.prospero.dto.CryptoPanicResponse;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestTemplate;
import org.springframework.web.util.UriComponentsBuilder;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.ZoneId;
import java.time.format.DateTimeFormatter;
import java.util.ArrayList;
import java.util.List;
import java.util.stream.Collectors;

@Service
@Slf4j
public class CryptoPanicService {

    private static final String CRYPTOPANIC_API_URL = "https://cryptopanic.com/api/v1/posts/";

    @Value("${cryptopanic.api.key:default}")
    private String apiKey;

    private final RestTemplate restTemplate;

    public CryptoPanicService() {
        this.restTemplate = new RestTemplate();
    }

    /**
     * 특정 날짜의 핫 뉴스 조회 (일 단위)
     *
     * @param date 조회할 날짜 (yyyyMMdd 형식)
     * @return 해당 날짜의 핫 뉴스 목록
     */
    public List<CryptoNews> getHotNewsByDate(String date) {
        try {
            LocalDate localDate = parseDate(date);
            LocalDateTime startOfDay = localDate.atStartOfDay();
            LocalDateTime endOfDay = localDate.plusDays(1).atStartOfDay().minusSeconds(1);

            log.info("조회 범위: {} ~ {}", startOfDay, endOfDay);

            String url = buildUrl(startOfDay, endOfDay);
            log.info("CryptoPanic API 호출: {}", url);

            CryptoPanicResponse response = restTemplate.getForObject(url, CryptoPanicResponse.class);

            if (response == null || response.getResults() == null) {
                log.warn("API 응답이 비어있습니다");
                return new ArrayList<>();
            }

            return filterHotNews(response.getResults(), startOfDay, endOfDay);
        } catch (Exception e) {
            log.error("CryptoPanic API 호출 중 오류 발생", e);
            throw new RuntimeException("뉴스 조회 실패: " + e.getMessage());
        }
    }

    /**
     * 최근 핫 뉴스 조회
     *
     * @param limit 조회 건수
     * @return 최근 핫 뉴스 목록
     */
    public List<CryptoNews> getLatestHotNews(int limit) {
        try {
            String url = UriComponentsBuilder.fromHttpUrl(CRYPTOPANIC_API_URL)
                    .queryParam("auth_token", apiKey)
                    .queryParam("kind", "news")
                    .queryParam("public", "true")
                    .queryParam("limit", limit)
                    .build()
                    .toUriString();

            log.info("CryptoPanic API 호출: {}", url);
            CryptoPanicResponse response = restTemplate.getForObject(url, CryptoPanicResponse.class);

            if (response == null || response.getResults() == null) {
                log.warn("API 응답이 비어있습니다");
                return new ArrayList<>();
            }

            return response.getResults();
        } catch (Exception e) {
            log.error("CryptoPanic API 호출 중 오류 발생", e);
            throw new RuntimeException("뉴스 조회 실패: " + e.getMessage());
        }
    }

    /**
     * URL 빌드
     */
    private String buildUrl(LocalDateTime startOfDay, LocalDateTime endOfDay) {
        DateTimeFormatter formatter = DateTimeFormatter.ISO_DATE_TIME;

        return UriComponentsBuilder.fromHttpUrl(CRYPTOPANIC_API_URL)
                .queryParam("auth_token", apiKey)
                .queryParam("kind", "news")
                .queryParam("public", "true")
                .queryParam("published_since", startOfDay.format(formatter))
                .queryParam("published_until", endOfDay.format(formatter))
                .build()
                .toUriString();
    }

    /**
     * 핫 뉴스 필터링 (kind = "news" 확인)
     */
    private List<CryptoNews> filterHotNews(List<CryptoNews> newsList,
                                            LocalDateTime startOfDay,
                                            LocalDateTime endOfDay) {
        return newsList.stream()
                .filter(news -> news.getCreatedAt() != null)
                .filter(news -> !news.getCreatedAt().isBefore(startOfDay)
                        && !news.getCreatedAt().isAfter(endOfDay))
                .collect(Collectors.toList());
    }

    /**
     * 날짜 문자열 파싱 (yyyyMMdd 형식)
     */
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
