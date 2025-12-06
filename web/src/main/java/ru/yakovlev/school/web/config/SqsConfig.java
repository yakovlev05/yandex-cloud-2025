package ru.yakovlev.school.web.config;

import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import software.amazon.awssdk.awscore.exception.AwsServiceException;
import software.amazon.awssdk.core.exception.SdkClientException;
import software.amazon.awssdk.regions.Region;
import software.amazon.awssdk.services.sqs.SqsClient;
import software.amazon.awssdk.services.sqs.model.*;
import software.amazon.awssdk.services.sqs.model.UnsupportedOperationException;

import java.net.URI;

/**
 * AWS SQS - очереди сообщений
 */
@Configuration
public class SqsConfig {

    @Bean
    @ConditionalOnProperty(name = "IS_CLOUD_ENV", havingValue = "true")
    public SqsClient sqsClient() {
        return SqsClient.builder()
                .region(Region.of("ru-central1"))
                .endpointOverride(URI.create("https://message-queue.api.cloud.yandex.net"))
                .build();
    }


    @Bean
    @ConditionalOnProperty(name = "IS_CLOUD_ENV", havingValue = "false")
    public SqsClient sqsClientDev() {
        return new SqsClient() {
            @Override
            public String serviceName() {
                return "";
            }

            @Override
            public void close() {

            }

            @Override
            public GetQueueUrlResponse getQueueUrl(GetQueueUrlRequest getQueueUrlRequest)
                    throws RequestThrottledException, QueueDoesNotExistException, InvalidAddressException,
                    InvalidSecurityException, UnsupportedOperationException, AwsServiceException,
                    SdkClientException, SqsException {
                return GetQueueUrlResponse.builder()
                        .queueUrl("dev")
                        .build();
            }

            @Override
            public SendMessageResponse sendMessage(SendMessageRequest sendMessageRequest)
                    throws InvalidMessageContentsException, UnsupportedOperationException, RequestThrottledException,
                    QueueDoesNotExistException, InvalidSecurityException, KmsDisabledException,
                    KmsInvalidStateException, KmsNotFoundException, KmsOptInRequiredException, KmsThrottledException,
                    KmsAccessDeniedException, KmsInvalidKeyUsageException, InvalidAddressException, AwsServiceException,
                    SdkClientException, SqsException {
                return SendMessageResponse.builder().build();
            }
        };
    }

}
