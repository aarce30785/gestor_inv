package org.example.controller;

import jakarta.servlet.http.HttpSession;
import org.example.dao.CompraProveedorDAO;
import org.example.dao.ProveedorDAO;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.servlet.mvc.support.RedirectAttributes;

import java.math.BigDecimal;

@Controller
@RequestMapping("/compras")
public class CompraProveedorController {

    @Autowired
    private CompraProveedorDAO compraProveedorDAO;

    @Autowired
    private ProveedorDAO proveedorDAO;

    @GetMapping
    public String verCompras(Model model) {
        cargarData(model);
        return "compras";
    }

    @PostMapping("/registrar")
    public String registrarCompra(@RequestParam String codigoProducto,
                                  @RequestParam Long idProveedor,
                                  @RequestParam int cantidad,
                                  @RequestParam BigDecimal costoUnitario,
                                  @RequestParam(required = false) String observacion,
                                  @RequestParam(required = false) Integer stockMinimo,
                                  HttpSession session,
                                  RedirectAttributes ra,
                                  Model model) {
        try {
            String usuario = (String) session.getAttribute("usuario");
            compraProveedorDAO.registrarCompra(
                    codigoProducto,
                    idProveedor,
                    usuario,
                    cantidad,
                    costoUnitario,
                    observacion,
                    stockMinimo
            );

            ra.addFlashAttribute("success", "Compra registrada y stock actualizado.");
            return "redirect:/compras";
        } catch (RuntimeException e) {
            model.addAttribute("error", e.getMessage());
            cargarData(model);
            return "compras";
        }
    }

    private void cargarData(Model model) {
        model.addAttribute("compras", compraProveedorDAO.listarComprasRecientes());
        model.addAttribute("proveedores", proveedorDAO.listarProveedoresActivos());
        model.addAttribute("productos", proveedorDAO.listarProductosActivos());
    }
}

