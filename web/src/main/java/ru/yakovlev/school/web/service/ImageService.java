package ru.yakovlev.school.web.service;

import lombok.RequiredArgsConstructor;
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

    private static final String GENERATE_QUEUE = "generate-image";

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

    private void sendGenerateMessage(Image image) {
        GetQueueUrlRequest getQueueRequest = GetQueueUrlRequest.builder()
                .queueName(GENERATE_QUEUE)
                .build();

        String queueUrl = sqsClient.getQueueUrl(getQueueRequest).queueUrl();

        SendMessageRequest sendMessageRequest = SendMessageRequest.builder()
                .queueUrl(queueUrl)
                .messageBody("id=%s||prompt=%s".formatted(image.getId(), image.getPrompt()))
                .build();

        sqsClient.sendMessage(sendMessageRequest);
    }
}
