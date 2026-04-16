package org.example.controller;

import jakarta.servlet.http.HttpSession;
import org.example.dao.ProductoDAO;
import org.example.dto.ProductoDTO;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.servlet.mvc.support.RedirectAttributes;

import java.math.BigDecimal;

@Controller
@RequestMapping("/productos")
public class ProductoController {

    @Autowired
    private ProductoDAO productoDAO;

    // LISTAR + BUSCAR
    @GetMapping
    public String verProductos(
            @RequestParam(required = false) String busqueda,
            Model model) {

        model.addAttribute("productos",
                productoDAO.listarProductos(busqueda));
        model.addAttribute("busqueda",
                busqueda != null ? busqueda : "");

        return "productos";
    }

    // FORM EDITAR
    @GetMapping("/editar/{codigo}")
    public String editarForm(@PathVariable String codigo, Model model) {
        ProductoDTO producto = productoDAO.obtenerProductoPorCodigo(codigo);
        model.addAttribute("producto", producto);

        return "producto-editar";
    }

    @PostMapping("/editar")
    public String editarProducto(ProductoDTO producto, RedirectAttributes ra, HttpSession session) {
        String usuario = (String) session.getAttribute("usuario");
        productoDAO.editarProducto(producto, usuario);
        ra.addFlashAttribute("success", "Producto actualizado correctamente.");
        return "redirect:/productos";
    }

    // DESACTIVAR (eliminación lógica)
    @PostMapping("/eliminar")
    public String eliminarProducto(@RequestParam String codigo, RedirectAttributes ra, HttpSession session) {
        String usuario = (String) session.getAttribute("usuario");
        productoDAO.eliminarProducto(codigo, usuario);
        ra.addFlashAttribute("success", "Producto desactivado correctamente.");
        return "redirect:/productos";
    }

    @GetMapping("/nuevo")
    public String nuevoProducto() {
        return "producto-nuevo";
    }

    @PostMapping("/guardar")
    public String guardarProducto(
            @RequestParam String codigo,
            @RequestParam String nombre,
            @RequestParam String descripcion,
            @RequestParam String categoria,
            @RequestParam BigDecimal precio,
            Model model,
            RedirectAttributes ra,
            HttpSession session
    ) {
        try {
            String usuario = (String) session.getAttribute("usuario");
            productoDAO.insertarProducto(codigo, nombre, descripcion, categoria, precio, usuario);
            ra.addFlashAttribute("success", "Producto registrado correctamente.");
            return "redirect:/productos";
        } catch (RuntimeException e) {
            model.addAttribute("error", e.getMessage());
            return "producto-nuevo";
        }
    }


}
