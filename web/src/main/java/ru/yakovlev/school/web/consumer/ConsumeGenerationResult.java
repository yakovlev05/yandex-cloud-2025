package ru.yakovlev.school.web.consumer;

import jakarta.annotation.PostConstruct;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;
import ru.yakovlev.school.web.entity.Image;
import ru.yakovlev.school.web.entity.ImageStatus;
import ru.yakovlev.school.web.service.ImageService;
import software.amazon.awssdk.services.sqs.SqsClient;
import software.amazon.awssdk.services.sqs.model.*;

import java.util.concurrent.TimeUnit;

@Slf4j
@RequiredArgsConstructor
@Component
public class ConsumeGenerationResult {

    private final SqsClient sqsClient;
    private final ImageService imageService;

    @Value("${queue.done-image}")
    private String queueDoneImage;

    private String queueUrl;

    @PostConstruct
    public void init() {
        GetQueueUrlRequest getQueueRequest = GetQueueUrlRequest.builder()
                .queueName(queueDoneImage)
                .build();

        queueUrl = sqsClient.getQueueUrl(getQueueRequest).queueUrl();
    }

    @Scheduled(fixedDelay = 1, timeUnit = TimeUnit.SECONDS)
    public void pollMessages() {

        ReceiveMessageRequest receiveMessageRequest = ReceiveMessageRequest.builder()
                .queueUrl(queueUrl)
                .maxNumberOfMessages(1)
                .waitTimeSeconds(20)
                .build();

        ReceiveMessageResponse receiveMessageResponse = sqsClient.receiveMessage(receiveMessageRequest);
        if (receiveMessageResponse.hasMessages()) {
            receiveMessageResponse.messages().forEach(this::processMessage);
        }
    }

    private void processMessage(Message message) {
        try {
            log.info("Processing message: {}", message.body());

            String id = parseId(message.body());
            boolean isSuccess = parseSuccess(message.body());

            imageService.getById(id).ifPresent(image -> processImage(image, isSuccess));
        } catch (Exception e) {
            log.atError()
                    .setMessage("Error processing message. Message: {}. Error: {}.")
                    .addArgument(message.body())
                    .addArgument(e.getMessage())
                    .setCause(e)
                    .log();
        } finally {
            sqsClient.deleteMessage(DeleteMessageRequest.builder()
                    .queueUrl(queueUrl)
                    .receiptHandle(message.receiptHandle())
                    .build());
        }
    }

    private void processImage(Image image, boolean isSuccess) {
        ImageStatus status = isSuccess ? ImageStatus.SUCCESS : ImageStatus.FAILED;
        image.setStatus(status);
        imageService.save(image);
    }

    private String parseId(String raw) {
        return raw.split("\\|\\|")[0].split("=")[1];
    }

    private boolean parseSuccess(String raw) {
        return Boolean.parseBoolean(raw.split("\\|\\|")[1].split("=")[1]);
    }

}
