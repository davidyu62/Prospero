package com.prospero.controller;

import com.prospero.service.BinanceService;
import com.prospero.service.CoinMetricsService;
import com.prospero.service.FredService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

@RestController
@RequestMapping("/api/indicators")
@RequiredArgsConstructor
@Slf4j
public class MarketIndicatorController {

    private final BinanceService binanceService;
    private final CoinMetricsService coinMetricsService;
    private final FredService fredService;

    @GetMapping("/funding-rate")
    public ResponseEntity<Map<String, Object>> getFundingRate() {
        log.info("펀딩비 조회");
        try {
            Double fundingRate = binanceService.getFundingRate();
            // 과학 표기법 방지: 6자리 소수점
            String formattedRate = fundingRate != null ?
                    String.format("%.6f", fundingRate) :
                    null;
            return ResponseEntity.ok(Map.of(
                    "fundingRate", formattedRate,
                    "symbol", "BTCUSDT",
                    "unit", "percentage"
            ));
        } catch (Exception e) {
            log.error("펀딩비 조회 중 오류 발생", e);
            return ResponseEntity.badRequest().body(Map.of("error", e.getMessage()));
        }
    }

    @GetMapping("/active-addresses")
    public ResponseEntity<Map<String, Object>> getActiveAddresses(
            @RequestParam(required = false) String date) {
        log.info("활성 주소 수 조회 - 날짜: {}", date != null ? date : "오늘");
        try {
            Long activeAddresses = coinMetricsService.getActiveAddresses(date != null ? date : "");
            return ResponseEntity.ok(Map.of(
                    "activeAddresses", activeAddresses,
                    "asset", "btc",
                    "unit", "count"
            ));
        } catch (Exception e) {
            log.error("활성 주소 수 조회 중 오류 발생", e);
            return ResponseEntity.badRequest().body(Map.of("error", e.getMessage()));
        }
    }

    @GetMapping("/mvrv")
    public ResponseEntity<Map<String, Object>> getMvrv(
            @RequestParam(required = false) String date) {
        log.info("MVRV 조회 - 날짜: {}", date != null ? date : "오늘");
        try {
            Double mvrv = coinMetricsService.getMvrv(date != null ? date : "");
            return ResponseEntity.ok(Map.of(
                    "mvrv", mvrv,
                    "asset", "btc",
                    "meaning", "Market Value to Realized Value"
            ));
        } catch (Exception e) {
            log.error("MVRV 조회 중 오류 발생", e);
            return ResponseEntity.badRequest().body(Map.of("error", e.getMessage()));
        }
    }

    @GetMapping("/vix")
    public ResponseEntity<Map<String, Object>> getVix(
            @RequestParam(required = false) String date) {
        log.info("VIX 조회 - 날짜: {}", date != null ? date : "오늘");
        try {
            Double vix = fredService.getIndicator(date != null ? date : "", "vix");
            if (vix == null) {
                return ResponseEntity.ok(Map.of(
                        "vix", "데이터 없음",
                        "seriesId", "VIXCLS",
                        "meaning", "Volatility Index",
                        "note", "해당 날짜의 데이터가 없습니다"
                ));
            }
            return ResponseEntity.ok(Map.of(
                    "vix", vix,
                    "seriesId", "VIXCLS",
                    "meaning", "Volatility Index"
            ));
        } catch (Exception e) {
            log.error("VIX 조회 중 오류 발생", e);
            return ResponseEntity.badRequest().body(Map.of("error", e.getMessage()));
        }
    }

    @GetMapping("/gold")
    public ResponseEntity<Map<String, Object>> getGoldPrice(
            @RequestParam(required = false) String date) {
        log.info("금 가격 조회 - 날짜: {}", date != null ? date : "오늘");
        try {
            Double goldPrice = fredService.getIndicator(date != null ? date : "", "goldPrice");
            if (goldPrice == null) {
                return ResponseEntity.ok(Map.of(
                        "goldPrice", "데이터 없음",
                        "seriesId", "GOLDAMGBD228NLBM",
                        "unit", "USD per troy ounce",
                        "note", "해당 날짜의 데이터가 없거나 Series ID가 변경되었을 수 있습니다"
                ));
            }
            return ResponseEntity.ok(Map.of(
                    "goldPrice", goldPrice,
                    "seriesId", "GOLDAMGBD228NLBM",
                    "unit", "USD per troy ounce"
            ));
        } catch (Exception e) {
            log.error("금 가격 조회 중 오류 발생", e);
            return ResponseEntity.badRequest().body(Map.of("error", e.getMessage()));
        }
    }

    @GetMapping("/oil")
    public ResponseEntity<Map<String, Object>> getOilPrice(
            @RequestParam(required = false) String date) {
        log.info("WTI 원유 조회 - 날짜: {}", date != null ? date : "오늘");
        try {
            Double oilPrice = fredService.getIndicator(date != null ? date : "", "oilPrice");
            if (oilPrice == null) {
                return ResponseEntity.ok(Map.of(
                        "oilPrice", "데이터 없음",
                        "seriesId", "DCOILWTICO",
                        "type", "WTI Crude Oil",
                        "unit", "USD per barrel",
                        "note", "해당 날짜의 데이터가 없습니다"
                ));
            }
            return ResponseEntity.ok(Map.of(
                    "oilPrice", oilPrice,
                    "seriesId", "DCOILWTICO",
                    "type", "WTI Crude Oil",
                    "unit", "USD per barrel"
            ));
        } catch (Exception e) {
            log.error("원유 가격 조회 중 오류 발생", e);
            return ResponseEntity.badRequest().body(Map.of("error", e.getMessage()));
        }
    }

    @GetMapping("/yield-spread")
    public ResponseEntity<Map<String, Object>> getYieldSpread(
            @RequestParam(required = false) String date) {
        log.info("10Y-2Y 금리차 조회 - 날짜: {}", date != null ? date : "오늘");
        try {
            Double yieldSpread = fredService.getIndicator(date != null ? date : "", "yieldSpread");
            if (yieldSpread == null) {
                return ResponseEntity.ok(Map.of(
                        "yieldSpread", "데이터 없음",
                        "seriesId", "T10Y2Y",
                        "meaning", "10-Year minus 2-Year Treasury Yield Spread",
                        "unit", "percentage points",
                        "note", "해당 날짜의 데이터가 없습니다"
                ));
            }
            return ResponseEntity.ok(Map.of(
                    "yieldSpread", yieldSpread,
                    "seriesId", "T10Y2Y",
                    "meaning", "10-Year minus 2-Year Treasury Yield Spread",
                    "unit", "percentage points"
            ));
        } catch (Exception e) {
            log.error("금리차 조회 중 오류 발생", e);
            return ResponseEntity.badRequest().body(Map.of("error", e.getMessage()));
        }
    }

    @GetMapping("/breakeven-inflation")
    public ResponseEntity<Map<String, Object>> getBreakevenInflation(
            @RequestParam(required = false) String date) {
        log.info("기대 인플레이션 조회 - 날짜: {}", date != null ? date : "오늘");
        try {
            Double breakEvenInflation = fredService.getIndicator(date != null ? date : "", "breakEvenInflation");
            if (breakEvenInflation == null) {
                return ResponseEntity.ok(Map.of(
                        "breakEvenInflation", "데이터 없음",
                        "seriesId", "T10YIE",
                        "meaning", "10-Year Breakeven Inflation Rate",
                        "unit", "percentage",
                        "note", "해당 날짜의 데이터가 없습니다"
                ));
            }
            return ResponseEntity.ok(Map.of(
                    "breakEvenInflation", breakEvenInflation,
                    "seriesId", "T10YIE",
                    "meaning", "10-Year Breakeven Inflation Rate",
                    "unit", "percentage"
            ));
        } catch (Exception e) {
            log.error("기대 인플레이션 조회 중 오류 발생", e);
            return ResponseEntity.badRequest().body(Map.of("error", e.getMessage()));
        }
    }
}
