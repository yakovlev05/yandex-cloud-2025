package ru.yakovlev.school.web.controller;

import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.*;
import ru.yakovlev.school.web.dto.ImageInfo;
import ru.yakovlev.school.web.entity.Image;
import ru.yakovlev.school.web.entity.ImageStatus;
import ru.yakovlev.school.web.mapper.ImageMapper;
import ru.yakovlev.school.web.service.ImageService;

import java.util.List;

@RequiredArgsConstructor
@Controller
@RequestMapping("/images")
public class ImageController {

    private final ImageService imageService;
    private final ImageMapper imageMapper;

    @PostMapping("/generate")
    public String generate(@RequestParam String prompt) {
        Image image = new Image(ImageStatus.IN_PROCESS, prompt, prompt);
        imageService.generate(image);
        return "redirect:/images/" + image.getId();
    }

    @GetMapping("/{id}")
    public String viewImage(Model model, @PathVariable String id) {
        Image image = imageService.getExistsById(id).orElse(null);

        if (image != null) {
            model.addAttribute("image", imageMapper.toInfo(image, imageService.buildUrl(image)));
        } else {
            model.addAttribute("image", null);
        }

        return "viewImage";
    }

    @PostMapping("/{id}/update")
    public String updateImage(@PathVariable String id, @RequestParam String description) {
        Image image = imageService.getExistsById(id).orElse(null);

        if (image == null) {
            return "redirect:/";
        }

        image.setDescription(description);
        imageService.save(image);
        return "redirect:/images/" + image.getId();
    }

    @GetMapping("/gallery")
    public String gallery(Model model) {
        List<ImageInfo> imagesInfo = imageService.getGalleryImages().stream()
                .map(image -> imageMapper.toInfo(image, imageService.buildUrl(image)))
                .toList();

        model.addAttribute("images", imagesInfo);

        return "gallery";
    }

}
