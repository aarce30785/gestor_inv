package org.example.controller;

import org.example.dao.HistorialProductoDAO;
import org.example.dao.UsuarioDAO;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RequestMapping;

import java.sql.Date;
import java.time.LocalDate;
import java.util.Comparator;

@Controller
@RequestMapping("/historial-productos")
public class HistorialProductoController {

    @Autowired
    private HistorialProductoDAO historialProductoDAO;

    @Autowired
    private UsuarioDAO usuarioDAO;

    @GetMapping
    public String verHistorial(
            @RequestParam(required = false) String operacion,
            @RequestParam(required = false) String usuario,
            @RequestParam(required = false) String fechaDesde,
            @RequestParam(required = false) String fechaHasta,
            Model model
    ) {
        Date desde = null;
        Date hastaExclusiva = null;

        try {
            if (fechaDesde != null && !fechaDesde.trim().isEmpty()) {
                desde = Date.valueOf(LocalDate.parse(fechaDesde.trim()));
            }
            if (fechaHasta != null && !fechaHasta.trim().isEmpty()) {
                LocalDate hasta = LocalDate.parse(fechaHasta.trim()).plusDays(1);
                hastaExclusiva = Date.valueOf(hasta);
            }
        } catch (Exception e) {
            model.addAttribute("error", "Formato de fecha invalido.");
        }

        model.addAttribute("historial", historialProductoDAO.listarHistorialFiltrado(
                operacion,
                usuario,
                desde,
                hastaExclusiva
        ));

        model.addAttribute("operacion", operacion != null ? operacion : "");
        model.addAttribute("usuario", usuario != null ? usuario : "");
        model.addAttribute("fechaDesde", fechaDesde != null ? fechaDesde : "");
        model.addAttribute("fechaHasta", fechaHasta != null ? fechaHasta : "");
        model.addAttribute("usuariosFiltro", usuarioDAO.listarUsuarios().stream()
                .map(u -> u.getUsername())
                .filter(u -> u != null && !u.trim().isEmpty())
                .distinct()
                .sorted(Comparator.naturalOrder())
                .toList());

        return "historial-productos";
    }
}

