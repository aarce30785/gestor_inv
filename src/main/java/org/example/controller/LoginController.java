package org.example.controller;

import jakarta.servlet.http.HttpSession;
import org.example.dao.LoginDAO;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestParam;

@Controller
public class LoginController {

    @Autowired
    private LoginDAO loginDAO;

    @GetMapping("/login")
    public String loginForm(HttpSession session) {
        if (session.getAttribute("usuario") != null) {
            return "redirect:/productos";
        }
        return "login";
    }

    @PostMapping("/login")
    public String login(
            @RequestParam String username,
            @RequestParam String password,
            Model model,
            HttpSession session
    ) {
        try {
            String rol = loginDAO.login(username, password);

            session.setAttribute("usuario", username);
            session.setAttribute("rol", rol);

            return "redirect:/productos";

        } catch (RuntimeException e) {
            model.addAttribute("error", e.getMessage());
            return "login";
        }
    }

    @GetMapping("/logout")
    public String logout(HttpSession session) {
        session.invalidate();
        return "redirect:/login";
    }


}
