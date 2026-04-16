package org.example.dao;

import org.example.db.DatabaseConnection;
import org.example.dto.HistorialProductoDTO;
import org.springframework.stereotype.Repository;

import java.sql.Connection;
import java.sql.Date;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.List;

@Repository
public class HistorialProductoDAO {

    public List<HistorialProductoDTO> listarHistorialReciente() {
        return listarHistorialFiltrado(null, null, null, null);
    }

    public List<HistorialProductoDTO> listarHistorialFiltrado(
            String operacion,
            String usuario,
            Date fechaDesde,
            Date fechaHastaExclusiva
    ) {
        List<HistorialProductoDTO> historial = new ArrayList<>();

        StringBuilder sql = new StringBuilder("""
                SELECT codigo,
                       tipo_operacion,
                       nombre_anterior,
                       nombre_nuevo,
                       categoria_anterior,
                       categoria_nueva,
                       precio_anterior,
                       precio_nuevo,
                       activo_anterior,
                       activo_nuevo,
                       usuario_responsable,
                       fecha_operacion
                FROM historial_producto
                WHERE 1 = 1
                """);

        List<Object> params = new ArrayList<>();

        if (operacion != null && !operacion.trim().isEmpty()) {
            sql.append(" AND tipo_operacion = ?");
            params.add(operacion.trim());
        }

        if (usuario != null && !usuario.trim().isEmpty()) {
            sql.append(" AND UPPER(usuario_responsable) LIKE ?");
            params.add("%" + usuario.trim().toUpperCase() + "%");
        }

        if (fechaDesde != null) {
            sql.append(" AND fecha_operacion >= ?");
            params.add(fechaDesde);
        }

        if (fechaHastaExclusiva != null) {
            sql.append(" AND fecha_operacion < ?");
            params.add(fechaHastaExclusiva);
        }

        sql.append(" ORDER BY fecha_operacion DESC FETCH FIRST 40 ROWS ONLY");

        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql.toString())) {

            for (int i = 0; i < params.size(); i++) {
                ps.setObject(i + 1, params.get(i));
            }

            try (ResultSet rs = ps.executeQuery()) {

                while (rs.next()) {
                    historial.add(new HistorialProductoDTO(
                            rs.getString("codigo"),
                            rs.getString("tipo_operacion"),
                            rs.getString("nombre_anterior"),
                            rs.getString("nombre_nuevo"),
                            rs.getString("categoria_anterior"),
                            rs.getString("categoria_nueva"),
                            rs.getBigDecimal("precio_anterior"),
                            rs.getBigDecimal("precio_nuevo"),
                            rs.getString("activo_anterior"),
                            rs.getString("activo_nuevo"),
                            rs.getString("usuario_responsable"),
                            rs.getTimestamp("fecha_operacion")
                    ));
                }
            }

        } catch (SQLException e) {
            throw new RuntimeException("Error listando historial de productos", e);
        }

        return historial;
    }
}

