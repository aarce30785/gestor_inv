package org.example.dao;

import org.example.db.DatabaseConnection;
import org.example.dto.CompraProveedorDTO;
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

        String sql = "{ call pkg_proveedores.sp_listar_compras_recientes(?) }";

        try (Connection conn = DatabaseConnection.getConnection();
             CallableStatement cs = conn.prepareCall(sql)) {

            cs.registerOutParameter(1, Types.REF_CURSOR);

            cs.execute();

            try (ResultSet rs = (ResultSet) cs.getObject(1)) {
                while (rs.next()) {
                    compras.add(new CompraProveedorDTO(
                            rs.getTimestamp(1),
                            rs.getString(2),
                            rs.getString(3),
                            rs.getInt(4),
                            rs.getBigDecimal(5),
                            rs.getString(6)
                    ));
                }
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
            return "El producto seleccionado no existe o esta inactivo.";
        }
        if (message.contains("ORA-20202")) {
            return "El proveedor seleccionado no existe o esta inactivo.";
        }
        if (message.contains("ORA-20203")) {
            return "El producto no esta asociado al proveedor seleccionado.";
        }
        if (message.contains("ORA-20011")) {
            return "No se pudo aplicar el movimiento de stock por validacion de inventario.";
        }

        return "No se pudo registrar la compra.";
    }
}
