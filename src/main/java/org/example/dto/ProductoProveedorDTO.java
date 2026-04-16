package org.example.dto;

public class ProductoProveedorDTO {

    private String codigoProducto;
    private String nombreProducto;
    private Long idProveedor;
    private String nombreProveedor;

    public ProductoProveedorDTO(String codigoProducto, String nombreProducto, Long idProveedor, String nombreProveedor) {
        this.codigoProducto = codigoProducto;
        this.nombreProducto = nombreProducto;
        this.idProveedor = idProveedor;
        this.nombreProveedor = nombreProveedor;
    }

    public String getCodigoProducto() { return codigoProducto; }
    public String getNombreProducto() { return nombreProducto; }
    public Long getIdProveedor() { return idProveedor; }
    public String getNombreProveedor() { return nombreProveedor; }
}

