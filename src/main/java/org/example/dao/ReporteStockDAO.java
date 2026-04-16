package org.example.dao;

import org.example.db.DatabaseConnection;
import org.example.dto.ReporteStockDTO;
import org.springframework.stereotype.Repository;

import java.sql.CallableStatement;
import java.sql.Connection;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Types;
import java.util.ArrayList;
import java.util.List;

@Repository
public class ReporteStockDAO {


    public List<ReporteStockDTO> reporteStockMinimo() {
        List<ReporteStockDTO> productos = new ArrayList<>();

        String sql = "{ call pkg_reportes_stock.sp_reporte_stock_minimo_cursor(?) }";

        try (Connection conn = DatabaseConnection.getConnection();
             CallableStatement cs = conn.prepareCall(sql)) {

            cs.registerOutParameter(1, Types.REF_CURSOR);

            cs.execute();

            try (ResultSet rs = (ResultSet) cs.getObject(1)) {
                while (rs.next()) {
                    productos.add(new ReporteStockDTO(
                            rs.getString(1),
                            rs.getString(2),
                            rs.getInt(3),
                            rs.getInt(4)
                    ));
                }
            }

        } catch (SQLException e) {
            throw new RuntimeException("Error al generar reporte de stock mínimo", e);
        }

        return productos;
    }
}
