package org.example.dao;

import org.example.db.DatabaseConnection;
import org.example.dto.ProductoDTO;
import org.springframework.stereotype.Repository;

import java.math.BigDecimal;
import java.sql.*;
import java.util.ArrayList;
import java.util.List;

@Repository
public class ProductoDAO {

    public List<ProductoDTO> listarProductos(String busqueda) {
        List<ProductoDTO> productos = new ArrayList<>();

        String sql = "{ call pkg_productos.sp_listar_productos_cursor(?, ?) }";

        try (Connection conn = DatabaseConnection.getConnection();
             CallableStatement cs = conn.prepareCall(sql)) {

            cs.setString(1, busqueda);
            cs.registerOutParameter(2, Types.REF_CURSOR);

            cs.execute();

            try (ResultSet rs = (ResultSet) cs.getObject(2)) {
                while (rs.next()) {
                    productos.add(new ProductoDTO(
                            rs.getString(1),
                            rs.getString(2),
                            rs.getString(3),
                            rs.getBigDecimal(4),
                            rs.getInt(5)
                    ));
                }
            }

        } catch (SQLException e) {
            throw new RuntimeException("Error listando productos con búsqueda", e);
        }

        return productos;
    }


    public ProductoDTO obtenerProductoPorCodigo(String codigo) {
        try (Connection conn = DatabaseConnection.getConnection();
             CallableStatement cs = conn.prepareCall("{ call pkg_productos.sp_obtener_producto(?, ?, ?, ?, ?) }")) {

            cs.setString(1, codigo);                   // IN
            cs.registerOutParameter(2, Types.VARCHAR); // nombre
            cs.registerOutParameter(3, Types.VARCHAR); // descripcion
            cs.registerOutParameter(4, Types.VARCHAR); // categoría
            cs.registerOutParameter(5, Types.NUMERIC); // precio

            cs.execute();

            String nombre = cs.getString(2);
            if (nombre == null) return null;

            String descripcion = cs.getString(3);
            String categoria   = cs.getString(4);
            BigDecimal precio  = cs.getBigDecimal(5);

            return new ProductoDTO(codigo, nombre, descripcion, categoria, precio, null);
        } catch (SQLException e) {
            throw new RuntimeException("Error obteniendo producto", e);
        }
    }


    public void eliminarProducto(String codigo, String usuario) {
        String sql = "{ call pkg_productos.sp_eliminar_producto(?) }";

        try (Connection conn = DatabaseConnection.getConnection();
             CallableStatement cs = conn.prepareCall(sql)) {

            setClientIdentifier(conn, usuario);

            cs.setString(1, codigo);
            cs.execute();
        } catch (SQLException e) {
            throw new RuntimeException("Error eliminando producto", e);
        }
    }

    public void editarProducto(ProductoDTO p, String usuario) {
        String sql = "{ call pkg_productos.sp_editar_producto(?, ?, ?, ?, ?) }";

        try (Connection conn = DatabaseConnection.getConnection();
             CallableStatement cs = conn.prepareCall(sql)) {

            setClientIdentifier(conn, usuario);

            cs.setString(1, p.getCodigo());
            cs.setString(2, p.getNombre());
            cs.setString(3, p.getDescripcion());
            cs.setString(4, p.getCategoria());
            cs.setBigDecimal(5, p.getPrecio());

            cs.execute();
        } catch (SQLException e) {
            throw new RuntimeException("Error editando producto", e);
        }
    }

    public void insertarProducto(
            String codigo,
            String nombre,
            String descripcion,
            String categoria,
            BigDecimal precio,
            String usuario
    ) {

        String sql = "{ call pkg_productos.sp_insertar_producto(?, ?, ?, ?, ?) }";

        try (Connection conn = DatabaseConnection.getConnection();
             CallableStatement cs = conn.prepareCall(sql)) {

            setClientIdentifier(conn, usuario);

            cs.setString(1, codigo);
            cs.setString(2, nombre);
            cs.setString(3, descripcion);
            cs.setString(4, categoria);
            cs.setBigDecimal(5, precio);

            cs.execute();

        } catch (SQLException e) {
            throw new RuntimeException(e.getMessage(), e);
        }
    }

    private void setClientIdentifier(Connection conn, String usuario) throws SQLException {
        String actor = (usuario == null || usuario.trim().isEmpty()) ? "SISTEMA" : usuario.trim();
        try (CallableStatement cs = conn.prepareCall("BEGIN DBMS_SESSION.SET_IDENTIFIER(?); END;")) {
            cs.setString(1, actor);
            cs.execute();
        }
    }

}
