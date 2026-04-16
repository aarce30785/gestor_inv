package org.example.dao;

import org.example.db.DatabaseConnection;
import org.example.dto.ProductoDTO;
import org.example.dto.ReporteStockDTO;
import org.springframework.stereotype.Repository;

import java.math.BigDecimal;
import java.sql.CallableStatement;
import java.sql.Connection;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Types;
import java.util.ArrayList;
import java.util.List;

@Repository
public class ReporteStockDAO {

    public List<ProductoDTO> buscarPorCategoria(String categoria) {
        List<ProductoDTO> productos = new ArrayList<>();

        String sql = "{ call pkg_reportes.sp_buscar_productos(?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?) }";

        try (Connection conn = DatabaseConnection.getConnection();
             CallableStatement cs = conn.prepareCall(sql)) {

            if (categoria == null || categoria.trim().isEmpty()) {
                cs.setNull(1, Types.VARCHAR);
            } else {
                cs.setString(1, categoria.trim());
            }
            cs.setNull(2, Types.NUMERIC);
            cs.setNull(3, Types.NUMERIC);

            cs.registerOutParameter(4, Types.INTEGER);
            cs.registerOutParameter(5, Types.VARCHAR);
            cs.registerOutParameter(6, Types.VARCHAR);
            cs.registerOutParameter(7, Types.NUMERIC);
            cs.registerOutParameter(8, Types.VARCHAR);
            cs.registerOutParameter(9, Types.VARCHAR);
            cs.registerOutParameter(10, Types.NUMERIC);
            cs.registerOutParameter(11, Types.VARCHAR);
            cs.registerOutParameter(12, Types.VARCHAR);
            cs.registerOutParameter(13, Types.NUMERIC);
            cs.registerOutParameter(14, Types.VARCHAR);
            cs.registerOutParameter(15, Types.VARCHAR);
            cs.registerOutParameter(16, Types.NUMERIC);
            cs.registerOutParameter(17, Types.VARCHAR);
            cs.registerOutParameter(18, Types.VARCHAR);
            cs.registerOutParameter(19, Types.NUMERIC);

            cs.execute();

            int total = cs.getInt(4);
            int base = 5;
            for (int i = 0; i < total; i++) {
                String codigo = cs.getString(base + (i * 3));
                String nombre = cs.getString(base + 1 + (i * 3));
                BigDecimal precio = cs.getBigDecimal(base + 2 + (i * 3));
                productos.add(new ProductoDTO(codigo, nombre, categoria, precio, null));
            }

        } catch (SQLException e) {
            throw new RuntimeException("Error generando reporte por categoria", e);
        }

        return productos;
    }

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
