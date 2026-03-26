package org.example.controller;

import org.example.dao.ProductoDAO;
import org.example.dto.ProductoDTO;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.*;

import java.math.BigDecimal;
import java.util.List;

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
    public String editarProducto(ProductoDTO producto) {
        productoDAO.editarProducto(producto);
        return "redirect:/productos";
    }

    // ELIMINAR
    @PostMapping("/eliminar")
    public String eliminarProducto(@RequestParam String codigo) {
        productoDAO.eliminarProducto(codigo);
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
            Model model
    ) {
        try {
            productoDAO.insertarProducto(
                    codigo, nombre, descripcion, categoria, precio
            );
            return "redirect:/productos";
        } catch (RuntimeException e) {
            model.addAttribute("error", e.getMessage());
            return "producto-nuevo";
        }
    }


}
