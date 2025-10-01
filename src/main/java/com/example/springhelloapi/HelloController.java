package com.example.springhelloapi;

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

import java.time.ZoneId;
import java.time.ZonedDateTime;
import java.util.LinkedHashMap;
import java.util.Map;

@RestController
public class HelloController {

    @GetMapping("/hello")
    public Map<String, Object> hello() {
        ZonedDateTime koreaTime = ZonedDateTime.now(ZoneId.of("Asia/Seoul"));
        long timestamp = koreaTime.toInstant().toEpochMilli();
        
        Map<String, Object> response = new LinkedHashMap<>();
        response.put("koreaTime", koreaTime.toString());
        response.put("timestamp", timestamp);
        response.put("message", "Hello, World!");
        
        return response;
    }
}