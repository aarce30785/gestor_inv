package org.example.controller;

import org.example.dao.HistorialStockDAO;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;

@Controller
@RequestMapping("/historial-stock")
public class HistorialStockController {

    @Autowired
    private HistorialStockDAO historialStockDAO;

    @GetMapping
    public String verHistorial(Model model) {
        model.addAttribute("historial", historialStockDAO.listarHistorialReciente());
        return "historial-stock";
    }
}

