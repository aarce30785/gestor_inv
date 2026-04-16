package org.example.dto;

public class ProveedorDTO {

    private Long idProveedor;
    private String nombre;
    private String telefono;
    private String email;
    private String activo;

    public ProveedorDTO(Long idProveedor, String nombre, String telefono, String email, String activo) {
        this.idProveedor = idProveedor;
        this.nombre = nombre;
        this.telefono = telefono;
        this.email = email;
        this.activo = activo;
    }

    public Long getIdProveedor() { return idProveedor; }
    public String getNombre() { return nombre; }
    public String getTelefono() { return telefono; }
    public String getEmail() { return email; }
    public String getActivo() { return activo; }
}

