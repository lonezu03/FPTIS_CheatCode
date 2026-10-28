package com.fittrack.common.exception;

import org.junit.jupiter.api.Test;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.server.ResponseStatusException;
import org.springframework.test.web.servlet.setup.MockMvcBuilders;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

class ResponseStatusHandlerTest {
 @RestController static class Probe {
  @GetMapping("/probe/{status}") Object probe(@PathVariable int status){throw new ResponseStatusException(HttpStatus.valueOf(status),status==500?"secret internal detail":"Yêu cầu không hợp lệ");}
 }
 @Test void preservesExpectedHttpFailuresWithoutExposingServerDetails() throws Exception {
  var mvc=MockMvcBuilders.standaloneSetup(new Probe()).setControllerAdvice(new GlobalExceptionHandler()).build();
  for(int code:new int[]{400,403,404,409,423})mvc.perform(get("/probe/"+code)).andExpect(status().is(code)).andExpect(jsonPath("$.status").value(code)).andExpect(jsonPath("$.message").value("Yêu cầu không hợp lệ"));
  mvc.perform(get("/probe/500")).andExpect(status().isInternalServerError()).andExpect(jsonPath("$.message").value("Máy chủ chưa xử lý được yêu cầu"));
 }
}
