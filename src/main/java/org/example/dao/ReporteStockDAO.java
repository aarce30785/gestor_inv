package org.example.dao;

import org.example.db.DatabaseConnection;
import org.example.dto.ReporteStockDTO;
import org.springframework.stereotype.Repository;

import java.sql.CallableStatement;
import java.sql.Connection;
import java.sql.SQLException;
import java.sql.Types;
import java.util.ArrayList;
import java.util.List;

@Repository
public class ReporteStockDAO {

    public List<ReporteStockDTO> reporteStockMinimo() {
        List<ReporteStockDTO> productos = new ArrayList<>();

        String sql = "{ call pkg_reportes_stock.sp_reporte_stock_minimo(?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?) }";

        try (Connection conn = DatabaseConnection.getConnection();
             CallableStatement cs = conn.prepareCall(sql)) {

            // OUT p_total
            cs.registerOutParameter(1, Types.INTEGER);

            // Producto 1
            cs.registerOutParameter(2, Types.VARCHAR);
            cs.registerOutParameter(3, Types.VARCHAR);
            cs.registerOutParameter(4, Types.INTEGER);
            cs.registerOutParameter(5, Types.INTEGER);

            // Producto 2
            cs.registerOutParameter(6, Types.VARCHAR);
            cs.registerOutParameter(7, Types.VARCHAR);
            cs.registerOutParameter(8, Types.INTEGER);
            cs.registerOutParameter(9, Types.INTEGER);

            // Producto 3
            cs.registerOutParameter(10, Types.VARCHAR);
            cs.registerOutParameter(11, Types.VARCHAR);
            cs.registerOutParameter(12, Types.INTEGER);
            cs.registerOutParameter(13, Types.INTEGER);

            // Producto 4
            cs.registerOutParameter(14, Types.VARCHAR);
            cs.registerOutParameter(15, Types.VARCHAR);
            cs.registerOutParameter(16, Types.INTEGER);
            cs.registerOutParameter(17, Types.INTEGER);

            // Producto 5
            cs.registerOutParameter(18, Types.VARCHAR);
            cs.registerOutParameter(19, Types.VARCHAR);
            cs.registerOutParameter(20, Types.INTEGER);
            cs.registerOutParameter(21, Types.INTEGER);

            // Ejecutar procedimiento
            cs.execute();

            int total = cs.getInt(1);

            if (total >= 1)
                productos.add(new ReporteStockDTO(cs.getString(2), cs.getString(3), cs.getInt(4), cs.getInt(5)));
            if (total >= 2)
                productos.add(new ReporteStockDTO(cs.getString(6), cs.getString(7), cs.getInt(8), cs.getInt(9)));
            if (total >= 3)
                productos.add(new ReporteStockDTO(cs.getString(10), cs.getString(11), cs.getInt(12), cs.getInt(13)));
            if (total >= 4)
                productos.add(new ReporteStockDTO(cs.getString(14), cs.getString(15), cs.getInt(16), cs.getInt(17)));
            if (total >= 5)
                productos.add(new ReporteStockDTO(cs.getString(18), cs.getString(19), cs.getInt(20), cs.getInt(21)));

        } catch (SQLException e) {
            throw new RuntimeException("Error al generar reporte de stock mínimo", e);
        }

        return productos;
    }
}
