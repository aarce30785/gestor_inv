package org.example.dto;

import java.util.Date;

public class MovimientoDTO {

    private String codigoProducto;
    private String tipo;
    private int cantidad;
    private Date fecha;

    public MovimientoDTO(String codigoProducto, String tipo, int cantidad, Date fecha) {
        this.codigoProducto = codigoProducto;
        this.tipo = tipo;
        this.cantidad = cantidad;
        this.fecha = fecha;
    }

    public String getCodigoProducto() { return codigoProducto; }
    public String getTipo() { return tipo; }
    public int getCantidad() { return cantidad; }
    public Date getFecha() { return fecha; }
}
