package ru.yakovlev.school.web.dto;

import ru.yakovlev.school.web.entity.ImageStatus;

public record ImageInfo(
        String id,
        String prompt,
        String description,
        ImageStatus status,
        String url
) {
}
