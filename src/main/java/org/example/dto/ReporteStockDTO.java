package org.example.dto;

public class ReporteStockDTO {

    private String codigo;
    private String nombre;
    private Integer cantidadActual;
    private Integer stockMinimo;

    public ReporteStockDTO(String codigo, String nombre, Integer cantidadActual, Integer stockMinimo) {
        this.codigo = codigo;
        this.nombre = nombre;
        this.cantidadActual = cantidadActual;
        this.stockMinimo = stockMinimo;
    }

    // Getters y setters
    public String getCodigo() { return codigo; }
    public void setCodigo(String codigo) { this.codigo = codigo; }

    public String getNombre() { return nombre; }
    public void setNombre(String nombre) { this.nombre = nombre; }

    public Integer getCantidadActual() { return cantidadActual; }
    public void setCantidadActual(Integer cantidadActual) { this.cantidadActual = cantidadActual; }

    public Integer getStockMinimo() { return stockMinimo; }
    public void setStockMinimo(Integer stockMinimo) { this.stockMinimo = stockMinimo; }
}