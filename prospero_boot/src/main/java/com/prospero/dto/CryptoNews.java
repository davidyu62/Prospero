package com.prospero.dto;

import com.fasterxml.jackson.annotation.JsonProperty;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;
import java.util.List;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class CryptoNews {

    private Long id;

    private String title;

    private String description;

    private String url;

    @JsonProperty("created_at")
    private LocalDateTime createdAt;

    private String source;

    private String kind;

    private List<Cryptocurrency> currencies;

    @Data
    @NoArgsConstructor
    @AllArgsConstructor
    public static class Cryptocurrency {
        @JsonProperty("code")
        private String code;

        @JsonProperty("title")
        private String title;
    }
}
