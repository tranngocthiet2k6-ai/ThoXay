package vn.thoxay.wallet;
import com.fasterxml.jackson.databind.DeserializationFeature;
import org.springframework.boot.autoconfigure.jackson.Jackson2ObjectMapperBuilderCustomizer;
import org.springframework.context.annotation.*;
@Configuration
public class WalletJsonConfig {
    @Bean Jackson2ObjectMapperBuilderCustomizer wholeNumberInputs(){return builder->builder.featuresToDisable(DeserializationFeature.ACCEPT_FLOAT_AS_INT);}
}
