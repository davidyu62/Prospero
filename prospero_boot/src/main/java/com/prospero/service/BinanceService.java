package com.prospero.service;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestTemplate;

@Service
@Slf4j
public class BinanceService {

    private static final String BINANCE_FUNDING_RATE_URL = "https://fapi.binance.com/fapi/v1/fundingRate";
    private final RestTemplate restTemplate = new RestTemplate();
    private final ObjectMapper objectMapper = new ObjectMapper();

    public Double getFundingRate() {
        try {
            String url = BINANCE_FUNDING_RATE_URL + "?symbol=BTCUSDT&limit=1";
            log.info("Binance 펀딩비 조회: {}", url);

            String response = restTemplate.getForObject(url, String.class);
            JsonNode jsonArray = objectMapper.readTree(response);

            if (jsonArray.isArray() && jsonArray.size() > 0) {
                JsonNode firstElement = jsonArray.get(0);
                String fundingRateStr = firstElement.get("fundingRate").asText();
                return Double.parseDouble(fundingRateStr);
            }

            log.warn("Binance 펀딩비 응답이 비어있습니다");
            return null;
        } catch (Exception e) {
            log.error("Binance 펀딩비 조회 중 오류 발생", e);
            return null;
        }
    }
}
