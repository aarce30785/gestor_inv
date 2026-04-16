package org.example.controller;

import org.example.dao.UsuarioDAO;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.servlet.mvc.support.RedirectAttributes;

@Controller
@RequestMapping("/usuarios")
public class UsuarioController {

    @Autowired
    private UsuarioDAO usuarioDAO;

    @GetMapping
    public String verUsuarios(Model model) {
        model.addAttribute("usuarios", usuarioDAO.listarUsuarios());
        return "usuarios";
    }

    @PostMapping("/guardar")
    public String registrarUsuario(@RequestParam String username,
                                   @RequestParam String password,
                                   @RequestParam String rol,
                                   RedirectAttributes ra,
                                   Model model) {
        try {
            usuarioDAO.registrarUsuario(username, password, rol);
            ra.addFlashAttribute("success", "Usuario registrado correctamente.");
            return "redirect:/usuarios";
        } catch (RuntimeException e) {
            model.addAttribute("error", e.getMessage());
            model.addAttribute("usuarios", usuarioDAO.listarUsuarios());
            return "usuarios";
        }
    }

    @PostMapping("/rol")
    public String actualizarRol(@RequestParam String username,
                                @RequestParam String rol,
                                RedirectAttributes ra,
                                Model model) {
        try {
            usuarioDAO.actualizarRol(username, rol);
            ra.addFlashAttribute("success", "Rol actualizado correctamente.");
            return "redirect:/usuarios";
        } catch (RuntimeException e) {
            model.addAttribute("error", e.getMessage());
            model.addAttribute("usuarios", usuarioDAO.listarUsuarios());
            return "usuarios";
        }
    }

    @PostMapping("/desactivar")
    public String desactivarUsuario(@RequestParam String username,
                                    RedirectAttributes ra,
                                    Model model) {
        try {
            usuarioDAO.desactivarUsuario(username);
            ra.addFlashAttribute("success", "Usuario desactivado correctamente.");
            return "redirect:/usuarios";
        } catch (RuntimeException e) {
            model.addAttribute("error", e.getMessage());
            model.addAttribute("usuarios", usuarioDAO.listarUsuarios());
            return "usuarios";
        }
    }
}

