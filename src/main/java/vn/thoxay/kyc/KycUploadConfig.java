package vn.thoxay.kyc;

import jakarta.servlet.MultipartConfigElement;
import org.springframework.boot.web.servlet.MultipartConfigFactory;
import org.springframework.context.annotation.*;
import org.springframework.util.unit.DataSize;

@Configuration
public class KycUploadConfig {
    @Bean MultipartConfigElement multipartConfigElement() {
        var factory = new MultipartConfigFactory();
        factory.setMaxFileSize(DataSize.ofMegabytes(5));
        factory.setMaxRequestSize(DataSize.ofMegabytes(11));
        return factory.createMultipartConfig();
    }
}
