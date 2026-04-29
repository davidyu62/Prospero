package com.prospero.service;

import com.prospero.dto.CryptoNews;
import com.prospero.dto.CoinDeskResponseWrapper;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestTemplate;
import org.springframework.web.util.UriComponentsBuilder;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.ArrayList;
import java.util.List;
import java.util.stream.Collectors;

@Service
@Slf4j
public class CoinDeskService {

    private static final String COINDESK_API_URL = "https://api.coindesk.com/v1/news/";

    @Value("${coindesk.api.key}")
    private String apiKey;

    private final RestTemplate restTemplate;

    public CoinDeskService() {
        this.restTemplate = new RestTemplate();
    }

    /**
     * 특정 날짜의 뉴스 조회 (일 단위)
     *
     * @param date 조회할 날짜 (yyyyMMdd 형식)
     * @return 해당 날짜의 뉴스 목록
     */
    public List<CryptoNews> getNewsByDate(String date) {
        try {
            LocalDate localDate = parseDate(date);
            LocalDateTime startOfDay = localDate.atStartOfDay();
            LocalDateTime endOfDay = localDate.plusDays(1).atStartOfDay().minusSeconds(1);

            log.info("조회 범위: {} ~ {}", startOfDay, endOfDay);

            String url = buildUrl();
            log.info("CoinDesk API 호출: {}", url);

            CoinDeskResponseWrapper response = restTemplate.getForObject(url, CoinDeskResponseWrapper.class);

            if (response == null || response.getData() == null || response.getData().getFeed() == null) {
                log.warn("API 응답이 비어있습니다");
                return new ArrayList<>();
            }

            return filterNewsByDate(response.getData().getFeed(), startOfDay, endOfDay);
        } catch (Exception e) {
            log.error("CoinDesk API 호출 중 오류 발생", e);
            throw new RuntimeException("뉴스 조회 실패: " + e.getMessage());
        }
    }

    /**
     * 최근 뉴스 조회
     *
     * @param limit 조회 건수
     * @return 최근 뉴스 목록
     */
    public List<CryptoNews> getLatestNews(int limit) {
        try {
            String url = buildUrl();
            log.info("CoinDesk API 호출: {}", url);

            CoinDeskResponseWrapper response = restTemplate.getForObject(url, CoinDeskResponseWrapper.class);

            if (response == null || response.getData() == null || response.getData().getFeed() == null) {
                log.warn("API 응답이 비어있습니다");
                return new ArrayList<>();
            }

            List<CryptoNews> newsList = response.getData().getFeed();
            return newsList.stream()
                    .limit(limit)
                    .collect(Collectors.toList());
        } catch (Exception e) {
            log.error("CoinDesk API 호출 중 오류 발생", e);
            throw new RuntimeException("뉴스 조회 실패: " + e.getMessage());
        }
    }

    /**
     * URL 빌드
     */
    private String buildUrl() {
        return UriComponentsBuilder.fromHttpUrl(COINDESK_API_URL)
                .queryParam("token", apiKey)
                .build()
                .toUriString();
    }

    /**
     * 뉴스 필터링 (날짜 범위 확인)
     */
    private List<CryptoNews> filterNewsByDate(List<CryptoNews> newsList,
                                               LocalDateTime startOfDay,
                                               LocalDateTime endOfDay) {
        return newsList.stream()
                .filter(news -> news.getPublishedAt() != null)
                .filter(news -> !news.getPublishedAt().isBefore(startOfDay)
                        && !news.getPublishedAt().isAfter(endOfDay))
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
