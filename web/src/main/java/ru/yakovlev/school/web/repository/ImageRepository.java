package ru.yakovlev.school.web.repository;

import org.springframework.data.repository.CrudRepository;
import ru.yakovlev.school.web.entity.Image;

public interface ImageRepository extends CrudRepository<Image, String> {
}
