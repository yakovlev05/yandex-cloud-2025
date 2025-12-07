@import ru.yakovlev.school.web.dto.ImageInfo
@import ru.yakovlev.school.web.entity.ImageStatus

@param ImageInfo image

!{String description = image == null ? "не найдено" : image.description();}

<!DOCTYPE html>
<html lang="ru">
<head>
    <meta charset="UTF-8">
    <link rel="stylesheet" href="/css/global.css">
    <link rel="stylesheet" href="/css/images/view-image.css">
    <title>Изображение: ${description}</title>

    @if(image!=null && image.status().equals(ImageStatus.IN_PROCESS))
        <meta http-equiv="refresh" content="3">
    @endif
</head>
<body>
@if (image == null)
    <p>Изображение не найдено</p>
@elseif(image.status().equals(ImageStatus.IN_PROCESS))
    <p>Изображение пока не готово, пожалуйста, подождите...</p>
@elseif(image.status().equals(ImageStatus.FAILED))
    <p>При генерации произошла ошибка 😭, попробуйте сгенерировать новое изображение</p>
@else
    <div class="image-container">
        <img src="${image.url()}" alt="изображение" width="800"/>


        <h3 id="description-label">${image.description()}</h3>

        <form id="form-edit" action="/images/${image.id()}/update" method="post" class="hidden form-edit">
            <label for="description">Введите новое описание:</label>
            <textarea rows="5" cols="40" name="description" id="description"
                      required>${image.description()}</textarea>
            <input type="submit" value="Сохранить"/>
        </form>


        <p class="prompt-paragraph">Промпт: ${image.prompt()}</p>
        <div class="button-container">
            <button id="edit-button" onclick="handleEdit()">Редактировать описание</button>
        </div>
    </div>
@endif

<script>
    function handleEdit() {
        document.getElementById("description-label").classList.add("hidden")
        document.getElementById("edit-button").classList.add("hidden")
        document.getElementById("form-edit").classList.remove("hidden")
    }
</script>
</body>
</html>
