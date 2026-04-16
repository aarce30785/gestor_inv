package org.example.dao;

import org.example.db.DatabaseConnection;
import org.example.dto.UsuarioDTO;
import org.springframework.stereotype.Repository;

import java.sql.CallableStatement;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.List;

@Repository
public class UsuarioDAO {

    public void registrarUsuario(String username, String password, String rol) {
        String sql = "{ call pkg_usuarios.sp_registrar_usuario(?, ?, ?) }";

        try (Connection conn = DatabaseConnection.getConnection();
             CallableStatement cs = conn.prepareCall(sql)) {
            cs.setString(1, username);
            cs.setString(2, password);
            cs.setString(3, rol);
            cs.execute();
        } catch (SQLException e) {
            throw new RuntimeException(mapUserError(e), e);
        }
    }

    public void actualizarRol(String username, String rol) {
        String sql = "{ call pkg_usuarios.sp_actualizar_rol(?, ?) }";

        try (Connection conn = DatabaseConnection.getConnection();
             CallableStatement cs = conn.prepareCall(sql)) {
            cs.setString(1, username);
            cs.setString(2, rol);
            cs.execute();
        } catch (SQLException e) {
            throw new RuntimeException(mapUserError(e), e);
        }
    }

    public void desactivarUsuario(String username) {
        String sql = "{ call pkg_usuarios.sp_desactivar_usuario(?) }";

        try (Connection conn = DatabaseConnection.getConnection();
             CallableStatement cs = conn.prepareCall(sql)) {
            cs.setString(1, username);
            cs.execute();
        } catch (SQLException e) {
            throw new RuntimeException(mapUserError(e), e);
        }
    }

    public List<UsuarioDTO> listarUsuarios() {
        List<UsuarioDTO> usuarios = new ArrayList<>();

        String sql = """
                SELECT username, rol, activo, fecha_creacion
                FROM usuario
                ORDER BY fecha_creacion DESC
                """;

        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {

            while (rs.next()) {
                usuarios.add(new UsuarioDTO(
                        rs.getString("username"),
                        rs.getString("rol"),
                        rs.getString("activo"),
                        rs.getDate("fecha_creacion")
                ));
            }
        } catch (SQLException e) {
            throw new RuntimeException("Error listando usuarios", e);
        }

        return usuarios;
    }

    private String mapUserError(SQLException e) {
        String message = e.getMessage();
        if (message == null) {
            return "No se pudo completar la operacion de usuarios.";
        }
        if (message.contains("ORA-20301")) {
            return "Rol invalido. Use ADMIN u OPERADOR.";
        }
        if (message.contains("ORA-20302")) {
            return "El usuario ya existe.";
        }
        if (message.contains("ORA-20303")) {
            return "Usuario no activo o no existe.";
        }
        if (message.contains("ORA-20304")) {
            return "Debe indicar el nombre de usuario.";
        }
        if (message.contains("ORA-20305")) {
            return "Debe indicar una contrasena.";
        }
        return "No se pudo completar la operacion de usuarios.";
    }
}
