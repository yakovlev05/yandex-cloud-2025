@import ru.yakovlev.school.web.entity.Image
@import ru.yakovlev.school.web.entity.ImageStatus

@param Image image

!{String description = image == null ? "не найдено" : image.getDescription();}

<!DOCTYPE html>
<html lang="ru">
<head>
    <meta charset="UTF-8">
    <link rel="stylesheet" href="/css/global.css">
    <link rel="stylesheet" href="/css/images/view-image.css">
    <title>Изображение: ${description}</title>

    @if(image!=null && image.getStatus().equals(ImageStatus.IN_PROCESS))
        <meta http-equiv="refresh" content="3">
    @endif
</head>
<body>
@if (image == null)
    <p>Изображение не найдено</p>
@elseif(image.getStatus().equals(ImageStatus.IN_PROCESS))
    <p>Изображение пока не готово, пожалуйста, подождите...</p>
@else
    <div>
        <img src="/s3/images/${image.getId()}.jpg" alt="${image.getDescription()}"/>
        <p>${image.getDescription()}</p>
    </div>
@endif
</body>
</html>
