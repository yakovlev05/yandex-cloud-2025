package ru.yakovlev.school.web.mapper;

import org.springframework.stereotype.Component;
import ru.yakovlev.school.web.dto.ImageInfo;
import ru.yakovlev.school.web.entity.Image;

@Component
public class ImageMapper {

    public ImageInfo toInfo(Image image, String url) {
        return new ImageInfo(
                image.getId(),
                image.getPrompt(),
                image.getDescription(),
                image.getStatus(),
                url
        );
    }

}
