package com.prospero.controller;

import com.prospero.dto.CryptoNews;
import com.prospero.service.CryptoPanicService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.HashMap;
import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/news")
@RequiredArgsConstructor
@Slf4j
public class NewsController {

    private final CryptoPanicService cryptoPanicService;

    /**
     * 특정 날짜의 핫 뉴스 조회
     *
     * @param date 조회 날짜 (yyyyMMdd 형식, 예: 20260429)
     * @return 해당 날짜의 핫 뉴스 목록
     */
    @GetMapping("/hot-by-date")
    public ResponseEntity<Map<String, Object>> getHotNewsByDate(
            @RequestParam(defaultValue = "") String date) {
        log.info("핫 뉴스 조회 요청 - 날짜: {}", date);

        try {
            List<CryptoNews> newsList = cryptoPanicService.getHotNewsByDate(date);

            Map<String, Object> response = new HashMap<>();
            response.put("date", date);
            response.put("count", newsList.size());
            response.put("news", newsList);

            return ResponseEntity.ok(response);
        } catch (Exception e) {
            log.error("뉴스 조회 중 오류 발생", e);
            return ResponseEntity.badRequest()
                    .body(Map.of("error", e.getMessage()));
        }
    }

    /**
     * 최근 핫 뉴스 조회
     *
     * @param limit 조회 건수 (기본값: 30)
     * @return 최근 핫 뉴스 목록
     */
    @GetMapping("/latest")
    public ResponseEntity<Map<String, Object>> getLatestHotNews(
            @RequestParam(defaultValue = "30") int limit) {
        log.info("최근 핫 뉴스 조회 요청 - 건수: {}", limit);

        try {
            List<CryptoNews> newsList = cryptoPanicService.getLatestHotNews(limit);

            Map<String, Object> response = new HashMap<>();
            response.put("count", newsList.size());
            response.put("news", newsList);

            return ResponseEntity.ok(response);
        } catch (Exception e) {
            log.error("뉴스 조회 중 오류 발생", e);
            return ResponseEntity.badRequest()
                    .body(Map.of("error", e.getMessage()));
        }
    }

}
