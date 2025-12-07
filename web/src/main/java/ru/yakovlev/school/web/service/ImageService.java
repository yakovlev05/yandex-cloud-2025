package ru.yakovlev.school.web.service;

import lombok.RequiredArgsConstructor;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import ru.yakovlev.school.web.entity.Image;
import ru.yakovlev.school.web.entity.ImageStatus;
import ru.yakovlev.school.web.repository.ImageRepository;
import software.amazon.awssdk.services.sqs.SqsClient;
import software.amazon.awssdk.services.sqs.model.GetQueueUrlRequest;
import software.amazon.awssdk.services.sqs.model.SendMessageRequest;

import java.util.Optional;

@RequiredArgsConstructor
@Service
public class ImageService {

    private static final String S3_YANDEX_DOMAIN = "https://storage.yandexcloud.net/";

    @Value("${queue.generate-image}")
    private String generateQueue;

    @Value("${s3.bucket}")
    private String bucket;

    private final ImageRepository imageRepository;
    private final SqsClient sqsClient;


    public void generate(Image image) {
        save(image);
        sendGenerateMessage(image);
        //https://docs.aws.amazon.com/sdk-for-java/latest/developer-guide/java_sqs_code_examples.html
    }

    public void save(Image image) {
        imageRepository.save(image);
    }

    public Optional<Image> getExistsById(String id) {
        return imageRepository.findByIdAndStatusNot(id, ImageStatus.DELETED);
    }

    public String buildUrl(Image image) {
        return new StringBuilder(S3_YANDEX_DOMAIN)
                .append(bucket)
                .append("/")
                .append(image.getId())
                .append(".")
                .append("jpg")
                .toString();
    }

    private void sendGenerateMessage(Image image) {
        GetQueueUrlRequest getQueueRequest = GetQueueUrlRequest.builder()
                .queueName(generateQueue)
                .build();

        String queueUrl = sqsClient.getQueueUrl(getQueueRequest).queueUrl();

        SendMessageRequest sendMessageRequest = SendMessageRequest.builder()
                .queueUrl(queueUrl)
                .messageBody("id=%s||prompt=%s".formatted(image.getId(), image.getPrompt()))
                .build();

        sqsClient.sendMessage(sendMessageRequest);
    }

    public Optional<Image> getById(String id) {
        return imageRepository.findById(id);
    }
}
