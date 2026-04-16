package org.example.dao;

import org.example.db.DatabaseConnection;
import org.example.dto.MovimientoDTO;
import org.springframework.stereotype.Repository;

import java.sql.CallableStatement;
import java.sql.Connection;
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
            return "Tipo de movimiento invalido.";
        }
        if (message.contains("ORA-20002")) {
            return "El producto o el usuario no existe o esta inactivo.";
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

        // El procedimiento actual devuelve hasta 5 filas.
        if (limite > 5) {
            limite = 5;
        }

        List<MovimientoDTO> movimientos = listarMovimientosViaProcedure();
        if (movimientos.size() <= limite) {
            return movimientos;
        }

        return new ArrayList<>(movimientos.subList(0, limite));
    }

    public List<MovimientoDTO> listarMovimientosViaProcedure() {

        List<MovimientoDTO> lista = new ArrayList<>();

        String sql = "{ call pkg_movimientos.sp_listar_movimientos_cursor(?) }";

        try (Connection conn = DatabaseConnection.getConnection();
             CallableStatement cs = conn.prepareCall(sql)) {

            cs.registerOutParameter(1, Types.REF_CURSOR);

            cs.execute();

            try (ResultSet rs = (ResultSet) cs.getObject(1)) {
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
            throw new RuntimeException("Error listando movimientos", e);
        }

        return lista;
    }

}
