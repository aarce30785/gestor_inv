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

        String sql = "{ call pkg_productos.sp_listar_productos(?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?) }"; // 27 parámetros

        try (Connection conn = DatabaseConnection.getConnection();
             CallableStatement cs = conn.prepareCall(sql)) {

            // IN
            cs.setString(1, busqueda);

            // OUT
            cs.registerOutParameter(2, Types.INTEGER); // p_total

            // Producto 1
            cs.registerOutParameter(3, Types.VARCHAR);  // p_cod1
            cs.registerOutParameter(4, Types.VARCHAR);  // p_nom1
            cs.registerOutParameter(5, Types.VARCHAR);  // p_cat1
            cs.registerOutParameter(6, Types.NUMERIC);  // p_pre1
            cs.registerOutParameter(7, Types.INTEGER);  // p_stock1

            // Producto 2
            cs.registerOutParameter(8, Types.VARCHAR);  // p_cod2
            cs.registerOutParameter(9, Types.VARCHAR);  // p_nom2
            cs.registerOutParameter(10, Types.VARCHAR); // p_cat2
            cs.registerOutParameter(11, Types.NUMERIC);// p_pre2
            cs.registerOutParameter(12, Types.INTEGER);// p_stock2

            // Producto 3
            cs.registerOutParameter(13, Types.VARCHAR);// p_cod3
            cs.registerOutParameter(14, Types.VARCHAR);// p_nom3
            cs.registerOutParameter(15, Types.VARCHAR);// p_cat3
            cs.registerOutParameter(16, Types.NUMERIC);// p_pre3
            cs.registerOutParameter(17, Types.INTEGER);// p_stock3

            // Producto 4
            cs.registerOutParameter(18, Types.VARCHAR);// p_cod4
            cs.registerOutParameter(19, Types.VARCHAR);// p_nom4
            cs.registerOutParameter(20, Types.VARCHAR);// p_cat4
            cs.registerOutParameter(21, Types.NUMERIC);// p_pre4
            cs.registerOutParameter(22, Types.INTEGER);// p_stock4

            // Producto 5
            cs.registerOutParameter(23, Types.VARCHAR);// p_cod5
            cs.registerOutParameter(24, Types.VARCHAR);// p_nom5
            cs.registerOutParameter(25, Types.VARCHAR);// p_cat5
            cs.registerOutParameter(26, Types.NUMERIC);// p_pre5
            cs.registerOutParameter(27, Types.INTEGER);// p_stock5

            // Ejecutar procedure
            cs.execute();

            int total = cs.getInt(2);

            for (int i = 1; i <= total; i++) {
                int base = 3 + (i - 1) * 5; //  5 parámetros por producto

                productos.add(new ProductoDTO(
                        cs.getString(base),        // codigo
                        cs.getString(base + 1),    // nombre
                        cs.getString(base + 2),    // categoria
                        cs.getBigDecimal(base + 3),// precio
                        cs.getInt(base + 4)        // stock
                ));
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
