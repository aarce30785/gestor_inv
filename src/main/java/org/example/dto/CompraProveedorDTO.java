package org.example.dto;

import java.math.BigDecimal;
import java.util.Date;

public class CompraProveedorDTO {

    private Date fechaCompra;
    private String codigoProducto;
    private String nombreProveedor;
    private int cantidad;
    private BigDecimal costoUnitario;
    private String usuario;

    public CompraProveedorDTO(Date fechaCompra, String codigoProducto, String nombreProveedor,
                              int cantidad, BigDecimal costoUnitario, String usuario) {
        this.fechaCompra = fechaCompra;
        this.codigoProducto = codigoProducto;
        this.nombreProveedor = nombreProveedor;
        this.cantidad = cantidad;
        this.costoUnitario = costoUnitario;
        this.usuario = usuario;
    }

    public Date getFechaCompra() { return fechaCompra; }
    public String getCodigoProducto() { return codigoProducto; }
    public String getNombreProveedor() { return nombreProveedor; }
    public int getCantidad() { return cantidad; }
    public BigDecimal getCostoUnitario() { return costoUnitario; }
    public String getUsuario() { return usuario; }
}

