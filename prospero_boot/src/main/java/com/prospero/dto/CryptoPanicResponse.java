package com.prospero.dto;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.List;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class CryptoPanicResponse {

    private int count;

    private String next;

    private String previous;

    private List<CryptoNews> results;

}
