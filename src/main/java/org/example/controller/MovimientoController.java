package org.example.controller;

import jakarta.servlet.http.HttpSession;
import org.example.dao.MovimientoDAO;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;

@Controller
@RequestMapping("/movimientos")
public class MovimientoController {

    @Autowired
    private MovimientoDAO movimientoDAO;

    @GetMapping
    public String verMovimientos(Model model) {
        model.addAttribute("movimientos", movimientoDAO.listarMovimientos());
        return "movimientos";
    }

    @PostMapping("/registrar")
    public String registrarMovimiento(
            @RequestParam String codigoProducto,
            @RequestParam String tipo,
            @RequestParam int cantidad,
            @RequestParam(required = false) String observacion,
            @RequestParam(required = false) int stockMinimo,
            HttpSession session,
            Model model
    ) {
        try {
            String usuario = (String) session.getAttribute("usuario");

            movimientoDAO.registrarMovimiento(
                    codigoProducto, usuario, tipo, cantidad, observacion, stockMinimo
            );

            return "redirect:/movimientos";

        } catch (RuntimeException e) {
            model.addAttribute("error", e.getMessage());
            model.addAttribute("movimientos", movimientoDAO.listarMovimientos());
            return "movimientos";
        }
    }
}
