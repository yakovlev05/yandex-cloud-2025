package ru.yakovlev.school.web.controller;

import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;

@Controller
@RequestMapping("/images")
public class ImageController {

    @GetMapping("/generate")
    public String generate(Model model){
        return "generateImage";
    }

}
