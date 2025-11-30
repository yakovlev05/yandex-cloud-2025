package ru.yakovlev.school.web.service;

import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import ru.yakovlev.school.web.entity.Image;
import ru.yakovlev.school.web.entity.ImageStatus;
import ru.yakovlev.school.web.repository.ImageRepository;

import java.util.Optional;

@RequiredArgsConstructor
@Service
public class ImageService {

    private final ImageRepository imageRepository;


    public void generate(Image image) {
        save(image);
        //TODO: отправка в очередь
    }

    public void save(Image image) {
        imageRepository.save(image);
    }

    public Optional<Image> getExistsById(String id) {
        return imageRepository.findByIdAndStatusNot(id, ImageStatus.DELETED);
    }
}
