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

    private String id;

    private String title;

    private String description;

    private String url;

    @JsonProperty("published_at")
    private LocalDateTime publishedAt;

    private String source;

    private String image;

    @JsonProperty("categories")
    private List<String> categories;
}
