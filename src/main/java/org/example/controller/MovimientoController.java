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
import org.springframework.web.servlet.mvc.support.RedirectAttributes;

@Controller
@RequestMapping("/movimientos")
public class MovimientoController {

    @Autowired
    private MovimientoDAO movimientoDAO;

    @GetMapping
    public String verMovimientos(
            @RequestParam(required = false, defaultValue = "5") int limite,
            Model model
    ) {
        model.addAttribute("movimientos", movimientoDAO.listarMovimientosRecientes(limite));
        model.addAttribute("limite", limite);
        return "movimientos";
    }

    @PostMapping("/registrar")
    public String registrarMovimiento(
            @RequestParam String codigoProducto,
            @RequestParam String tipo,
            @RequestParam int cantidad,
            @RequestParam(required = false) String observacion,
            @RequestParam(required = false) Integer stockMinimo,
            HttpSession session,
            Model model,
            RedirectAttributes ra
    ) {
        try {
            String usuario = (String) session.getAttribute("usuario");

            movimientoDAO.registrarMovimiento(
                    codigoProducto, usuario, tipo, cantidad, observacion, stockMinimo
            );

            ra.addFlashAttribute("success", "Movimiento registrado correctamente.");
            return "redirect:/movimientos";

        } catch (RuntimeException e) {
            model.addAttribute("error", e.getMessage());
            model.addAttribute("movimientos", movimientoDAO.listarMovimientosRecientes(5));
            model.addAttribute("limite", 5);
            return "movimientos";
        }
    }
}
