package com.example.springhelloapi;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.context.annotation.ComponentScan;

@SpringBootApplication
@ComponentScan(basePackages = {"com.example.demo", "com.example.springhelloapi"})
public class HelloApiApplication {
    public static void main(String[] args) {
        SpringApplication.run(HelloApiApplication.class, args);
    }
}