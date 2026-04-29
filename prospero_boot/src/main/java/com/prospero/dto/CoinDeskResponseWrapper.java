package com.prospero.dto;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.List;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class CoinDeskResponseWrapper {

    private String status;

    private CoinDeskData data;

    @Data
    @NoArgsConstructor
    @AllArgsConstructor
    public static class CoinDeskData {
        private List<CryptoNews> feed;
    }
}
