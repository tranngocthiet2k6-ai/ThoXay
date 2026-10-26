package vn.thoxay.notification;

import com.google.auth.oauth2.GoogleCredentials;
import com.google.firebase.*;
import com.google.firebase.messaging.FirebaseMessaging;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.context.annotation.*;
import org.springframework.scheduling.concurrent.ThreadPoolTaskScheduler;

@Configuration
public class FirebaseConfig {
    @Bean(destroyMethod = "delete") @ConditionalOnProperty(name = "app.fcm.enabled", havingValue = "true")
    FirebaseApp firebaseApp(@Value("${app.fcm.project-id}") String projectId) throws Exception {
        return FirebaseApp.initializeApp(FirebaseOptions.builder().setProjectId(projectId)
            .setCredentials(GoogleCredentials.getApplicationDefault()).setConnectTimeout(5000).setReadTimeout(5000).build(), "thoxay");
    }
    @Bean @ConditionalOnProperty(name = "app.fcm.enabled", havingValue = "true")
    FirebaseMessaging firebaseMessaging(FirebaseApp app) { return FirebaseMessaging.getInstance(app); }
    @Bean
    ThreadPoolTaskScheduler taskScheduler() {
        var scheduler = new ThreadPoolTaskScheduler(); scheduler.setPoolSize(3); scheduler.setThreadNamePrefix("scheduled-"); return scheduler;
    }
}
