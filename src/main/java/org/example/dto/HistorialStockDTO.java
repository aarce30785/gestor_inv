package org.example.dto;

import java.util.Date;

public class HistorialStockDTO {

    private String codigoProducto;
    private Integer cantidadAnterior;
    private Integer cantidadNueva;
    private Integer stockMinimoAnterior;
    private Integer stockMinimoNuevo;
    private String usuarioResponsable;
    private String origen;
    private Date fechaCambio;

    public HistorialStockDTO(String codigoProducto, Integer cantidadAnterior, Integer cantidadNueva,
                             Integer stockMinimoAnterior, Integer stockMinimoNuevo,
                             String usuarioResponsable, String origen, Date fechaCambio) {
        this.codigoProducto = codigoProducto;
        this.cantidadAnterior = cantidadAnterior;
        this.cantidadNueva = cantidadNueva;
        this.stockMinimoAnterior = stockMinimoAnterior;
        this.stockMinimoNuevo = stockMinimoNuevo;
        this.usuarioResponsable = usuarioResponsable;
        this.origen = origen;
        this.fechaCambio = fechaCambio;
    }

    public String getCodigoProducto() { return codigoProducto; }
    public Integer getCantidadAnterior() { return cantidadAnterior; }
    public Integer getCantidadNueva() { return cantidadNueva; }
    public Integer getStockMinimoAnterior() { return stockMinimoAnterior; }
    public Integer getStockMinimoNuevo() { return stockMinimoNuevo; }
    public String getUsuarioResponsable() { return usuarioResponsable; }
    public String getOrigen() { return origen; }
    public Date getFechaCambio() { return fechaCambio; }
}

