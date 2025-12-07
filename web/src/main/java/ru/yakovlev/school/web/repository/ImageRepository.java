package ru.yakovlev.school.web.repository;

import org.springframework.data.repository.CrudRepository;
import ru.yakovlev.school.web.entity.Image;
import ru.yakovlev.school.web.entity.ImageStatus;

import java.util.Collection;
import java.util.List;
import java.util.Optional;

public interface ImageRepository extends CrudRepository<Image, String> {
    Optional<Image> findByIdAndStatusNot(String id, ImageStatus status);

    List<Image> findAllByStatusIn(Collection<ImageStatus> statuses);
}
