package org.example.controller;


import org.example.dao.ReporteStockDAO;
import org.example.dto.ProductoDTO;
import org.example.dto.ReporteStockDTO;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestParam;

import java.util.List;

@Controller
public class ReporteStockController {

    private final ReporteStockDAO reporteStockDAO;

    public ReporteStockController(ReporteStockDAO reporteStockDAO) {
        this.reporteStockDAO = reporteStockDAO;
    }

    @GetMapping("/reportes/stock-minimo")
    public String mostrarStockMinimo(Model model) {
        List<ReporteStockDTO> productos = reporteStockDAO.reporteStockMinimo();
        model.addAttribute("productos", productos);
        return "stock_minimo";
    }

    @GetMapping("/reportes/categoria")
    public String mostrarReportePorCategoria(
            @RequestParam(required = false) String categoria,
            Model model
    ) {
        List<ProductoDTO> productos = reporteStockDAO.buscarPorCategoria(categoria);
        model.addAttribute("productos", productos);
        model.addAttribute("categoria", categoria != null ? categoria : "");
        return "reporte-categoria";
    }
}
