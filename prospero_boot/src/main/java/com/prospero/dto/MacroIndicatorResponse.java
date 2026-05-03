package com.prospero.dto;

import com.fasterxml.jackson.annotation.JsonInclude;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
@JsonInclude(JsonInclude.Include.NON_NULL)
public class MacroIndicatorResponse {

    private Double vix;
    private Double goldPrice;
    private Double oilPrice;
    private Double yieldSpread;
    private Double breakEvenInflation;
    private String date;
}
