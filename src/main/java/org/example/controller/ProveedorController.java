package org.example.controller;

import org.example.dao.ProveedorDAO;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.servlet.mvc.support.RedirectAttributes;

@Controller
@RequestMapping("/proveedores")
public class ProveedorController {

    @Autowired
    private ProveedorDAO proveedorDAO;

    @GetMapping
    public String verProveedores(Model model) {
        cargarData(model);
        return "proveedores";
    }

    @PostMapping("/guardar")
    public String guardarProveedor(@RequestParam String nombre,
                                   @RequestParam(required = false) String telefono,
                                   @RequestParam(required = false) String email,
                                   RedirectAttributes ra,
                                   Model model) {
        try {
            proveedorDAO.registrarProveedor(nombre, telefono, email);
            ra.addFlashAttribute("success", "Proveedor registrado correctamente.");
            return "redirect:/proveedores";
        } catch (RuntimeException e) {
            model.addAttribute("error", e.getMessage());
            cargarData(model);
            return "proveedores";
        }
    }

    @PostMapping("/asociar")
    public String asociarProductoProveedor(@RequestParam String codigoProducto,
                                           @RequestParam Long idProveedor,
                                           RedirectAttributes ra,
                                           Model model) {
        try {
            proveedorDAO.asociarProductoProveedor(codigoProducto, idProveedor);
            ra.addFlashAttribute("success", "Asociación producto-proveedor registrada.");
            return "redirect:/proveedores";
        } catch (RuntimeException e) {
            model.addAttribute("error", e.getMessage());
            cargarData(model);
            return "proveedores";
        }
    }

    private void cargarData(Model model) {
        model.addAttribute("proveedores", proveedorDAO.listarProveedoresActivos());
        model.addAttribute("productos", proveedorDAO.listarProductosActivos());
        model.addAttribute("asociaciones", proveedorDAO.listarAsociacionesActivas());
    }
}

