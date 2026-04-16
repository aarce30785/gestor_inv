package org.example.dao;

import org.example.db.DatabaseConnection;
import org.example.dto.HistorialStockDTO;
import org.springframework.stereotype.Repository;

import java.sql.CallableStatement;
import java.sql.Connection;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Types;
import java.util.ArrayList;
import java.util.List;

@Repository
public class HistorialStockDAO {

    public List<HistorialStockDTO> listarHistorialReciente() {
        List<HistorialStockDTO> historial = new ArrayList<>();

        String sql = "{ call pkg_historial_stock.sp_listar_historial_reciente(?) }";

        try (Connection conn = DatabaseConnection.getConnection();
             CallableStatement cs = conn.prepareCall(sql)) {

            cs.registerOutParameter(1, Types.REF_CURSOR);
            cs.execute();

            try (ResultSet rs = (ResultSet) cs.getObject(1)) {
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
            }
        } catch (SQLException e) {
            throw new RuntimeException("Error listando historial de stock", e);
        }

        return historial;
    }
}
