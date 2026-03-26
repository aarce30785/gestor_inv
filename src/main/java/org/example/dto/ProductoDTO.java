package org.example.dto;

import java.math.BigDecimal;

public class ProductoDTO {

    private String codigo;
    private String nombre;
    private String categoria;
    private BigDecimal precio;
    private Integer stock;

    public ProductoDTO(String codigo, String nombre, String categoria, BigDecimal precio, Integer stock) {
        this.codigo = codigo;
        this.nombre = nombre;
        this.categoria = categoria;
        this.precio = precio;
        this.stock = stock;
    }

    public String getCodigo() { return codigo; }
    public String getNombre() { return nombre; }
    public String getCategoria() { return categoria; }
    public BigDecimal getPrecio() { return precio; }
    public Integer getStock() { return stock; }

    // setters
    public void setCodigo(String codigo) { this.codigo = codigo; }
    public void setNombre(String nombre) { this.nombre = nombre; }
    public void setCategoria(String categoria) { this.categoria = categoria; }
    public void setPrecio(BigDecimal precio) { this.precio = precio; }
    public void setStock(Integer stock) { this.stock = stock; }
}
