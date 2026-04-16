package org.example.dao;

import org.example.db.DatabaseConnection;
import org.example.dto.CompraProveedorDTO;
import org.springframework.stereotype.Repository;

import java.math.BigDecimal;
import java.sql.CallableStatement;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Types;
import java.util.ArrayList;
import java.util.List;

@Repository
public class CompraProveedorDAO {

    public void registrarCompra(String codigoProducto,
                                Long idProveedor,
                                String usuario,
                                int cantidad,
                                BigDecimal costoUnitario,
                                String observacion,
                                Integer stockMinimo) {

        String sql = "{ call pkg_proveedores.sp_registrar_compra(?, ?, ?, ?, ?, ?, ?) }";

        try (Connection conn = DatabaseConnection.getConnection();
             CallableStatement cs = conn.prepareCall(sql)) {

            cs.setString(1, codigoProducto);
            cs.setLong(2, idProveedor);
            cs.setString(3, usuario);
            cs.setInt(4, cantidad);
            cs.setBigDecimal(5, costoUnitario);
            cs.setString(6, observacion);
            if (stockMinimo == null) {
                cs.setNull(7, Types.NUMERIC);
            } else {
                cs.setInt(7, stockMinimo);
            }

            cs.execute();
        } catch (SQLException e) {
            throw new RuntimeException(mapCompraError(e), e);
        }
    }

    public List<CompraProveedorDTO> listarComprasRecientes() {
        List<CompraProveedorDTO> compras = new ArrayList<>();

        String sql = """
                SELECT c.fecha_compra,
                       p.codigo,
                       pr.nombre AS proveedor,
                       c.cantidad,
                       c.costo_unitario,
                       u.username
                FROM compra_proveedor c
                JOIN producto p ON p.id_producto = c.id_producto
                JOIN proveedor pr ON pr.id_proveedor = c.id_proveedor
                JOIN usuario u ON u.id_usuario = c.id_usuario
                ORDER BY c.fecha_compra DESC
                FETCH FIRST 10 ROWS ONLY
                """;

        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {

            while (rs.next()) {
                compras.add(new CompraProveedorDTO(
                        rs.getTimestamp("fecha_compra"),
                        rs.getString("codigo"),
                        rs.getString("proveedor"),
                        rs.getInt("cantidad"),
                        rs.getBigDecimal("costo_unitario"),
                        rs.getString("username")
                ));
            }
        } catch (SQLException e) {
            throw new RuntimeException("Error listando compras recientes", e);
        }

        return compras;
    }

    private String mapCompraError(SQLException e) {
        String message = e.getMessage();
        if (message == null) {
            return "No se pudo registrar la compra.";
        }

        if (message.contains("ORA-20201")) {
            return "El producto seleccionado no existe o está inactivo.";
        }
        if (message.contains("ORA-20202")) {
            return "El proveedor seleccionado no existe o está inactivo.";
        }
        if (message.contains("ORA-20203")) {
            return "El producto no está asociado al proveedor seleccionado.";
        }
        if (message.contains("ORA-20011")) {
            return "No se pudo aplicar el movimiento de stock por validación de inventario.";
        }

        return "No se pudo registrar la compra.";
    }
}

