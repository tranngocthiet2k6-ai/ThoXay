package vn.thoxay;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.web.servlet.MockMvc;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@SpringBootTest(properties = "app.cors.origins=https://thoxay-demo.vercel.app") @AutoConfigureMockMvc
class DeploymentConfigurationTest {
    @Autowired MockMvc mvc;
    @Test void healthIsPublicAndDoesNotDiscloseDatabaseCredentials() throws Exception {
        mvc.perform(get("/health")).andExpect(status().isOk()).andExpect(content().json("{\"status\":\"UP\"}"));
    }
    @Test void readinessAliasIsPublicAndUsesTheConfiguredVercelCorsOrigin() throws Exception {
        mvc.perform(get("/api/auth/health").header("Origin", "https://thoxay-demo.vercel.app"))
            .andExpect(status().isOk()).andExpect(content().json("{\"status\":\"UP\"}"))
            .andExpect(header().string("Access-Control-Allow-Origin", "https://thoxay-demo.vercel.app"));
    }
    @Test void exactVercelOriginCanSendAuthenticatedMultipartRequests() throws Exception {
        mvc.perform(options("/api/users/me/cccd/photos").header("Origin", "https://thoxay-demo.vercel.app")
            .header("Access-Control-Request-Method", "POST").header("Access-Control-Request-Headers", "authorization,content-type"))
            .andExpect(status().isOk()).andExpect(header().string("Access-Control-Allow-Origin", "https://thoxay-demo.vercel.app"));
    }
    @Test void unrelatedPreviewDomainIsNotAutomaticallyTrusted() throws Exception {
        mvc.perform(options("/api/users/me").header("Origin", "https://other-preview.vercel.app")
            .header("Access-Control-Request-Method", "GET"))
            .andExpect(status().isForbidden()).andExpect(header().doesNotExist("Access-Control-Allow-Origin"));
    }
}
