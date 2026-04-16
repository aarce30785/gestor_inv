package org.example.dao;

import org.example.db.DatabaseConnection;
import org.example.dto.MovimientoDTO;
import org.springframework.stereotype.Repository;

import java.sql.CallableStatement;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
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
            Integer stockMinimo
    ) {

        String sql = "{ call pkg_movimientos.sp_registrar_movimiento(?,?,?,?,?,?) }";

        try (Connection conn = DatabaseConnection.getConnection();
             CallableStatement cs = conn.prepareCall(sql)) {

            cs.setString(1, codigoProducto);
            cs.setString(2, usuario);
            cs.setString(3, tipo);
            cs.setInt(4, cantidad);
            cs.setString(5, observacion);
            if (stockMinimo == null) {
                cs.setNull(6, Types.NUMERIC);
            } else {
                cs.setInt(6, stockMinimo);
            }

            cs.execute();

        } catch (SQLException e) {
            throw new RuntimeException(mapMovementError(e), e);
        }
    }

    private String mapMovementError(SQLException e) {
        String message = e.getMessage();
        if (message == null) {
            return "No fue posible registrar el movimiento.";
        }

        if (message.contains("ORA-20011") || message.toLowerCase().contains("stock insuficiente")) {
            return "No se puede registrar la salida: stock insuficiente.";
        }
        if (message.contains("ORA-20001") && message.toLowerCase().contains("cantidad")) {
            return "La cantidad debe ser mayor a cero.";
        }
        if (message.contains("ORA-20001") && message.toLowerCase().contains("tipo")) {
            return "Tipo de movimiento inválido.";
        }
        if (message.contains("ORA-20002")) {
            return "El producto o el usuario no existe o está inactivo.";
        }

        return "No fue posible registrar el movimiento.";
    }

    public List<MovimientoDTO> listarMovimientos() {
        return listarMovimientosRecientes(5);
    }

    public List<MovimientoDTO> listarMovimientosRecientes(int limite) {

        if (limite < 1) {
            limite = 5;
        }

        if (limite > 50) {
            limite = 50;
        }

        List<MovimientoDTO> lista = new ArrayList<>();

        String sql = """
                SELECT p.codigo,
                       m.tipo_movimiento,
                       m.cantidad,
                       m.fecha_movimiento
                FROM movimiento m
                JOIN producto p ON p.id_producto = m.id_producto
                ORDER BY m.fecha_movimiento DESC
                FETCH FIRST ? ROWS ONLY
                """;

        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {

            ps.setInt(1, limite);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    lista.add(new MovimientoDTO(
                            rs.getString(1),
                            rs.getString(2),
                            rs.getInt(3),
                            rs.getTimestamp(4)
                    ));
                }
            }

        } catch (SQLException e) {
            throw new RuntimeException("Error listando movimientos recientes", e);
        }

        return lista;
    }

    public List<MovimientoDTO> listarMovimientosViaProcedure() {

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
            cs.registerOutParameter(i, Types.DATE);

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
