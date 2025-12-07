@import ru.yakovlev.school.web.dto.ImageInfo
@import java.util.List

@param List<ImageInfo> images

<!DOCTYPE html>
<html lang="ru">
<head>
    <meta charset="UTF-8">
    <link rel="stylesheet" href="/css/global.css">
    <link rel="stylesheet" href="/css/images/gallery.css">
    <title>Галерея</title>
</head>
<body>
@if (images.isEmpty())
    <div class="no-found-container">
        <p>Будьте первыми. Сгенерируйте изображение!</p>
    </div>
@else
    <div class="images-container">
        @for(ImageInfo image : images)
            <div class="image-box">
                <img src="${image.url()}" width="500" alt="изображение"/>
                <p>${image.description()}</p>
                <a href="/images/${image.id()}">Посмотреть</a>
            </div>
        @endfor
    </div>
@endif
</body>
</html>

