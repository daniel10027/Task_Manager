package com.taskmanager.controller;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.transaction.annotation.Transactional;

import java.util.Map;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles("test")
@Transactional
class TaskControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private ObjectMapper objectMapper;

    private String registerAndGetToken(String email) throws Exception {
        Map<String, String> body = Map.of(
                "email", email,
                "password", "Sup3rSecret!",
                "fullName", "Test User"
        );
        String responseJson = mockMvc.perform(post("/api/auth/register")
                        .contentType("application/json")
                        .content(objectMapper.writeValueAsString(body)))
                .andExpect(status().isCreated())
                .andReturn().getResponse().getContentAsString();

        JsonNode node = objectMapper.readTree(responseJson);
        return node.get("token").asText();
    }

    @Test
    void getTasks_withoutToken_returns401() throws Exception {
        mockMvc.perform(get("/api/tasks"))
                .andExpect(status().isUnauthorized())
                .andExpect(jsonPath("$.status").value(401));
    }

    @Test
    void getTasks_initiallyEmpty() throws Exception {
        String token = registerAndGetToken("empty@doe.com");

        mockMvc.perform(get("/api/tasks").header("Authorization", "Bearer " + token))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$").isArray())
                .andExpect(jsonPath("$.length()").value(0));
    }

    @Test
    void createTask_validRequest_returns201WithDefaultTodoStatus() throws Exception {
        String token = registerAndGetToken("create@doe.com");
        Map<String, String> body = Map.of("title", "Write report", "description", "Quarterly summary");

        mockMvc.perform(post("/api/tasks")
                        .header("Authorization", "Bearer " + token)
                        .contentType("application/json")
                        .content(objectMapper.writeValueAsString(body)))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.id").isNumber())
                .andExpect(jsonPath("$.title").value("Write report"))
                .andExpect(jsonPath("$.status").value("TODO"))
                .andExpect(jsonPath("$.createdAt").isNotEmpty())
                .andExpect(jsonPath("$.updatedAt").isNotEmpty());
    }

    @Test
    void createTask_blankTitle_returns400() throws Exception {
        String token = registerAndGetToken("blanktitle@doe.com");
        Map<String, String> body = Map.of("title", "", "description", "desc");

        mockMvc.perform(post("/api/tasks")
                        .header("Authorization", "Bearer " + token)
                        .contentType("application/json")
                        .content(objectMapper.writeValueAsString(body)))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.status").value(400));
    }

    @Test
    void getTasks_filtersByStatusAndSearch() throws Exception {
        String token = registerAndGetToken("filter@doe.com");

        createTask(token, "Buy milk", "groceries", "TODO");
        createTask(token, "Write report", "quarterly", "IN_PROGRESS");
        createTask(token, "Ship report", "final", "DONE");

        mockMvc.perform(get("/api/tasks?status=IN_PROGRESS").header("Authorization", "Bearer " + token))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.length()").value(1))
                .andExpect(jsonPath("$[0].title").value("Write report"));

        mockMvc.perform(get("/api/tasks?search=report").header("Authorization", "Bearer " + token))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.length()").value(2));

        mockMvc.perform(get("/api/tasks?status=DONE&search=report").header("Authorization", "Bearer " + token))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.length()").value(1))
                .andExpect(jsonPath("$[0].title").value("Ship report"));
    }

    @Test
    void updateTask_ownTask_returns200() throws Exception {
        String token = registerAndGetToken("update@doe.com");
        Long id = createTask(token, "Old title", "Old desc", "TODO");

        Map<String, String> updateBody = Map.of("title", "New title", "description", "New desc", "status", "DONE");

        mockMvc.perform(put("/api/tasks/{id}", id)
                        .header("Authorization", "Bearer " + token)
                        .contentType("application/json")
                        .content(objectMapper.writeValueAsString(updateBody)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.title").value("New title"))
                .andExpect(jsonPath("$.status").value("DONE"));
    }

    @Test
    void updateTask_notFound_returns404() throws Exception {
        String token = registerAndGetToken("notfound@doe.com");
        Map<String, String> updateBody = Map.of("title", "New title");

        mockMvc.perform(put("/api/tasks/{id}", 999999)
                        .header("Authorization", "Bearer " + token)
                        .contentType("application/json")
                        .content(objectMapper.writeValueAsString(updateBody)))
                .andExpect(status().isNotFound())
                .andExpect(jsonPath("$.status").value(404));
    }

    @Test
    void updateTask_belongingToAnotherUser_returns404() throws Exception {
        String ownerToken = registerAndGetToken("owner@doe.com");
        Long taskId = createTask(ownerToken, "Owner's task", "secret", "TODO");

        String intruderToken = registerAndGetToken("intruder@doe.com");
        Map<String, String> updateBody = Map.of("title", "Hijacked");

        mockMvc.perform(put("/api/tasks/{id}", taskId)
                        .header("Authorization", "Bearer " + intruderToken)
                        .contentType("application/json")
                        .content(objectMapper.writeValueAsString(updateBody)))
                .andExpect(status().isNotFound());
    }

    @Test
    void deleteTask_ownTask_returns204() throws Exception {
        String token = registerAndGetToken("delete@doe.com");
        Long id = createTask(token, "To delete", "bye", "TODO");

        mockMvc.perform(delete("/api/tasks/{id}", id).header("Authorization", "Bearer " + token))
                .andExpect(status().isNoContent());

        mockMvc.perform(get("/api/tasks").header("Authorization", "Bearer " + token))
                .andExpect(jsonPath("$.length()").value(0));
    }

    @Test
    void deleteTask_belongingToAnotherUser_returns404() throws Exception {
        String ownerToken = registerAndGetToken("owner2@doe.com");
        Long taskId = createTask(ownerToken, "Owner's task", "secret", "TODO");

        String intruderToken = registerAndGetToken("intruder2@doe.com");

        mockMvc.perform(delete("/api/tasks/{id}", taskId).header("Authorization", "Bearer " + intruderToken))
                .andExpect(status().isNotFound());
    }

    @Test
    void deleteTask_notFound_returns404() throws Exception {
        String token = registerAndGetToken("delnotfound@doe.com");

        mockMvc.perform(delete("/api/tasks/{id}", 999999).header("Authorization", "Bearer " + token))
                .andExpect(status().isNotFound());
    }

    private Long createTask(String token, String title, String description, String status) throws Exception {
        Map<String, String> body = Map.of("title", title, "description", description, "status", status);
        String responseJson = mockMvc.perform(post("/api/tasks")
                        .header("Authorization", "Bearer " + token)
                        .contentType("application/json")
                        .content(objectMapper.writeValueAsString(body)))
                .andExpect(status().isCreated())
                .andReturn().getResponse().getContentAsString();
        return objectMapper.readTree(responseJson).get("id").asLong();
    }
}
