package ru.yakovlev.school.web.controller;

import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.*;
import ru.yakovlev.school.web.entity.Image;
import ru.yakovlev.school.web.entity.ImageStatus;
import ru.yakovlev.school.web.service.ImageService;

@RequiredArgsConstructor
@Controller
@RequestMapping("/images")
public class ImageController {

    private final ImageService imageService;

    @PostMapping("/generate")
    public String generate(Model model, @RequestParam String prompt) {
        Image image = new Image(ImageStatus.IN_PROCESS, prompt, prompt);
        imageService.generate(image);
        return "redirect:/images/" + image.getId();
    }

    @GetMapping("/{id}")
    public String viewImage(Model model, @PathVariable String id) {
        Image image = imageService.getExistsById(id).orElse(null);
        model.addAttribute("image", image);
        return "viewImage";
    }

}
