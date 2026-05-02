package com.prospero.controller;

import com.prospero.dto.CryptoIndicatorResponse;
import com.prospero.dto.MacroIndicatorResponse;
import com.prospero.service.BinanceService;
import com.prospero.service.CoinMetricsService;
import com.prospero.service.FredService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;

@RestController
@RequestMapping("/api/indicators")
@RequiredArgsConstructor
@Slf4j
public class MarketIndicatorController {

    private final BinanceService binanceService;
    private final CoinMetricsService coinMetricsService;
    private final FredService fredService;

    @GetMapping("/crypto")
    public ResponseEntity<CryptoIndicatorResponse> getCryptoIndicators(
            @RequestParam(required = false) String date) {
        log.info("암호화폐 지표 조회 - 날짜: {}", date != null ? date : "오늘");

        try {
            Double fundingRate = binanceService.getFundingRate();
            Long activeAddresses = coinMetricsService.getActiveAddresses(date != null ? date : "");
            Double mvrv = coinMetricsService.getMvrv(date != null ? date : "");

            String timestamp = LocalDateTime.now().format(DateTimeFormatter.ISO_DATE_TIME);

            CryptoIndicatorResponse response = CryptoIndicatorResponse.builder()
                    .fundingRate(fundingRate)
                    .activeAddresses(activeAddresses)
                    .mvrv(mvrv)
                    .timestamp(timestamp)
                    .build();

            return ResponseEntity.ok(response);
        } catch (Exception e) {
            log.error("암호화폐 지표 조회 중 오류 발생", e);
            return ResponseEntity.badRequest().build();
        }
    }

    @GetMapping("/macro")
    public ResponseEntity<MacroIndicatorResponse> getMacroIndicators(
            @RequestParam(required = false) String date) {
        log.info("거시경제 지표 조회 - 날짜: {}", date != null ? date : "오늘");

        try {
            MacroIndicatorResponse response = fredService.getMacroIndicators(date != null ? date : "");
            return ResponseEntity.ok(response);
        } catch (Exception e) {
            log.error("거시경제 지표 조회 중 오류 발생", e);
            return ResponseEntity.badRequest().build();
        }
    }
}
