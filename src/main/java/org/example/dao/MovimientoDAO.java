package org.example.dao;

import org.example.db.DatabaseConnection;
import org.example.dto.MovimientoDTO;
import org.springframework.stereotype.Repository;

import java.sql.CallableStatement;
import java.sql.Connection;
import java.sql.SQLException;
import java.sql.Types;
import java.util.ArrayList;
import java.util.List;

@Repository
public class MovimientoDAO {

    public void registrarMovimiento(
            String codigoProducto,
            String usuario,
            String tipo,
            int cantidad,
            String observacion,
            int stockMinimo
    ) {

        String sql = "{ call pkg_movimientos.sp_registrar_movimiento(?,?,?,?,?,?) }";

        try (Connection conn = DatabaseConnection.getConnection();
             CallableStatement cs = conn.prepareCall(sql)) {

            cs.setString(1, codigoProducto);
            cs.setString(2, usuario);
            cs.setString(3, tipo);
            cs.setInt(4, cantidad);
            cs.setString(5, observacion);
            cs.setInt(6, stockMinimo);

            cs.execute();

        } catch (SQLException e) {
            throw new RuntimeException(e.getMessage(), e);
        }
    }

    public List<MovimientoDTO> listarMovimientos() {

        List<MovimientoDTO> lista = new ArrayList<>();

        String sql = "{ call pkg_movimientos.sp_listar_movimientos(?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?) }";

        try (Connection conn = DatabaseConnection.getConnection();
             CallableStatement cs = conn.prepareCall(sql)) {

            int i = 1;

            cs.registerOutParameter(i++, Types.INTEGER); // p_total

            // prod1
            cs.registerOutParameter(i++, Types.VARCHAR);
            cs.registerOutParameter(i++, Types.VARCHAR);
            cs.registerOutParameter(i++, Types.INTEGER);
            cs.registerOutParameter(i++, Types.DATE);

            // prod2
            cs.registerOutParameter(i++, Types.VARCHAR);
            cs.registerOutParameter(i++, Types.VARCHAR);
            cs.registerOutParameter(i++, Types.INTEGER);
            cs.registerOutParameter(i++, Types.DATE);

            // prod3
            cs.registerOutParameter(i++, Types.VARCHAR);
            cs.registerOutParameter(i++, Types.VARCHAR);
            cs.registerOutParameter(i++, Types.INTEGER);
            cs.registerOutParameter(i++, Types.DATE);

            // prod4
            cs.registerOutParameter(i++, Types.VARCHAR);
            cs.registerOutParameter(i++, Types.VARCHAR);
            cs.registerOutParameter(i++, Types.INTEGER);
            cs.registerOutParameter(i++, Types.DATE);

            // prod5
            cs.registerOutParameter(i++, Types.VARCHAR);
            cs.registerOutParameter(i++, Types.VARCHAR);
            cs.registerOutParameter(i++, Types.INTEGER);
            cs.registerOutParameter(i++, Types.DATE);

            cs.execute();

            int total = cs.getInt(1);
            int index = 2;

            for (int n = 0; n < total; n++) {
                lista.add(new MovimientoDTO(
                        cs.getString(index++), // codigo
                        cs.getString(index++), // tipo
                        cs.getInt(index++),    // cantidad
                        cs.getDate(index++)    // fecha
                ));
            }

        } catch (SQLException e) {
            throw new RuntimeException("Error listando movimientos", e);
        }

        return lista;
    }

}
