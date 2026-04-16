package org.example.dto;

import java.util.Date;

public class UsuarioDTO {

    private String username;
    private String rol;
    private String activo;
    private Date fechaCreacion;

    public UsuarioDTO(String username, String rol, String activo, Date fechaCreacion) {
        this.username = username;
        this.rol = rol;
        this.activo = activo;
        this.fechaCreacion = fechaCreacion;
    }

    public String getUsername() { return username; }
    public String getRol() { return rol; }
    public String getActivo() { return activo; }
    public Date getFechaCreacion() { return fechaCreacion; }
}

