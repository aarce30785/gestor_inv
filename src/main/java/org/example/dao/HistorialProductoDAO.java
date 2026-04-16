package org.example.dao;

import org.example.db.DatabaseConnection;
import org.example.dto.HistorialProductoDTO;
import org.springframework.stereotype.Repository;

import java.sql.CallableStatement;
import java.sql.Connection;
import java.sql.Date;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Types;
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

        String sql = "{ call pkg_historial_producto.sp_listar_historial_filtrado(?, ?, ?, ?, ?) }";

        try (Connection conn = DatabaseConnection.getConnection();
             CallableStatement cs = conn.prepareCall(sql)) {

            if (operacion == null || operacion.trim().isEmpty()) {
                cs.setNull(1, Types.VARCHAR);
            } else {
                cs.setString(1, operacion.trim());
            }

            if (usuario == null || usuario.trim().isEmpty()) {
                cs.setNull(2, Types.VARCHAR);
            } else {
                cs.setString(2, usuario.trim());
            }

            if (fechaDesde == null) {
                cs.setNull(3, Types.DATE);
            } else {
                cs.setDate(3, fechaDesde);
            }

            if (fechaHastaExclusiva == null) {
                cs.setNull(4, Types.DATE);
            } else {
                cs.setDate(4, fechaHastaExclusiva);
            }

            cs.registerOutParameter(5, Types.REF_CURSOR);
            cs.execute();

            try (ResultSet rs = (ResultSet) cs.getObject(5)) {
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

