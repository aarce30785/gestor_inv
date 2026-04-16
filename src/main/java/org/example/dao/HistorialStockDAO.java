package org.example.dao;

import org.example.db.DatabaseConnection;
import org.example.dto.HistorialStockDTO;
import org.springframework.stereotype.Repository;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.List;

@Repository
public class HistorialStockDAO {

    public List<HistorialStockDTO> listarHistorialReciente() {
        List<HistorialStockDTO> historial = new ArrayList<>();

        String sql = """
                SELECT p.codigo,
                       h.cantidad_anterior,
                       h.cantidad_nueva,
                       h.stock_minimo_anterior,
                       h.stock_minimo_nuevo,
                       h.usuario_responsable,
                       h.origen,
                       h.fecha_cambio
                FROM historial_stock h
                JOIN inventario i ON i.id_inventario = h.id_inventario
                JOIN producto p ON p.id_producto = i.id_producto
                ORDER BY h.fecha_cambio DESC
                FETCH FIRST 30 ROWS ONLY
                """;

        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {

            while (rs.next()) {
                historial.add(new HistorialStockDTO(
                        rs.getString("codigo"),
                        rs.getInt("cantidad_anterior"),
                        rs.getInt("cantidad_nueva"),
                        rs.getInt("stock_minimo_anterior"),
                        rs.getInt("stock_minimo_nuevo"),
                        rs.getString("usuario_responsable"),
                        rs.getString("origen"),
                        rs.getTimestamp("fecha_cambio")
                ));
            }
        } catch (SQLException e) {
            throw new RuntimeException("Error listando historial de stock", e);
        }

        return historial;
    }
}
