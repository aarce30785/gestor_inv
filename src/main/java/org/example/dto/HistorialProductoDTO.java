package org.example.dto;

import java.math.BigDecimal;
import java.util.Date;

public class HistorialProductoDTO {

    private String codigo;
    private String tipoOperacion;
    private String nombreAnterior;
    private String nombreNuevo;
    private String categoriaAnterior;
    private String categoriaNuevo;
    private BigDecimal precioAnterior;
    private BigDecimal precioNuevo;
    private String activoAnterior;
    private String activoNuevo;
    private String usuarioResponsable;
    private Date fechaOperacion;

    public HistorialProductoDTO(String codigo, String tipoOperacion,
                                String nombreAnterior, String nombreNuevo,
                                String categoriaAnterior, String categoriaNuevo,
                                BigDecimal precioAnterior, BigDecimal precioNuevo,
                                String activoAnterior, String activoNuevo,
                                String usuarioResponsable, Date fechaOperacion) {
        this.codigo = codigo;
        this.tipoOperacion = tipoOperacion;
        this.nombreAnterior = nombreAnterior;
        this.nombreNuevo = nombreNuevo;
        this.categoriaAnterior = categoriaAnterior;
        this.categoriaNuevo = categoriaNuevo;
        this.precioAnterior = precioAnterior;
        this.precioNuevo = precioNuevo;
        this.activoAnterior = activoAnterior;
        this.activoNuevo = activoNuevo;
        this.usuarioResponsable = usuarioResponsable;
        this.fechaOperacion = fechaOperacion;
    }

    public String getCodigo() { return codigo; }
    public String getTipoOperacion() { return tipoOperacion; }
    public String getNombreAnterior() { return nombreAnterior; }
    public String getNombreNuevo() { return nombreNuevo; }
    public String getCategoriaAnterior() { return categoriaAnterior; }
    public String getCategoriaNuevo() { return categoriaNuevo; }
    public BigDecimal getPrecioAnterior() { return precioAnterior; }
    public BigDecimal getPrecioNuevo() { return precioNuevo; }
    public String getActivoAnterior() { return activoAnterior; }
    public String getActivoNuevo() { return activoNuevo; }
    public String getUsuarioResponsable() { return usuarioResponsable; }
    public Date getFechaOperacion() { return fechaOperacion; }
}

