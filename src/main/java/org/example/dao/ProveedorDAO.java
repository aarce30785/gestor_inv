package org.example.dao;

import org.example.db.DatabaseConnection;
import org.example.dto.ProductoDTO;
import org.example.dto.ProductoProveedorDTO;
import org.example.dto.ProveedorDTO;
import org.springframework.stereotype.Repository;

import java.sql.CallableStatement;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.List;

@Repository
public class ProveedorDAO {

    public void registrarProveedor(String nombre, String telefono, String email) {
        String sql = "{ call pkg_proveedores.sp_registrar_proveedor(?, ?, ?) }";

        try (Connection conn = DatabaseConnection.getConnection();
             CallableStatement cs = conn.prepareCall(sql)) {
            cs.setString(1, nombre);
            cs.setString(2, telefono);
            cs.setString(3, email);
            cs.execute();
        } catch (SQLException e) {
            throw new RuntimeException(mapProveedorError(e), e);
        }
    }

    public void asociarProductoProveedor(String codigoProducto, Long idProveedor) {
        String sql = "{ call pkg_proveedores.sp_asociar_producto_proveedor(?, ?) }";

        try (Connection conn = DatabaseConnection.getConnection();
             CallableStatement cs = conn.prepareCall(sql)) {
            cs.setString(1, codigoProducto);
            cs.setLong(2, idProveedor);
            cs.execute();
        } catch (SQLException e) {
            throw new RuntimeException(mapProveedorError(e), e);
        }
    }

    public List<ProveedorDTO> listarProveedoresActivos() {
        List<ProveedorDTO> proveedores = new ArrayList<>();
        String sql = """
                SELECT id_proveedor, nombre, telefono, email, activo
                FROM proveedor
                WHERE activo = 'S'
                ORDER BY nombre
                """;

        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {

            while (rs.next()) {
                proveedores.add(new ProveedorDTO(
                        rs.getLong("id_proveedor"),
                        rs.getString("nombre"),
                        rs.getString("telefono"),
                        rs.getString("email"),
                        rs.getString("activo")
                ));
            }
        } catch (SQLException e) {
            throw new RuntimeException("Error listando proveedores", e);
        }

        return proveedores;
    }

    public List<ProductoDTO> listarProductosActivos() {
        List<ProductoDTO> productos = new ArrayList<>();
        String sql = """
                SELECT codigo, nombre, categoria
                FROM producto
                WHERE activo = 'S'
                ORDER BY nombre
                """;

        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {

            while (rs.next()) {
                productos.add(new ProductoDTO(
                        rs.getString("codigo"),
                        rs.getString("nombre"),
                        null,
                        rs.getString("categoria"),
                        null,
                        null
                ));
            }
        } catch (SQLException e) {
            throw new RuntimeException("Error listando productos para proveedores", e);
        }

        return productos;
    }

    public List<ProductoProveedorDTO> listarAsociacionesActivas() {
        List<ProductoProveedorDTO> asociaciones = new ArrayList<>();
        String sql = """
                SELECT p.codigo, p.nombre AS nombre_producto,
                       pr.id_proveedor, pr.nombre AS nombre_proveedor
                FROM producto_proveedor pp
                JOIN producto p ON p.id_producto = pp.id_producto
                JOIN proveedor pr ON pr.id_proveedor = pp.id_proveedor
                WHERE pp.activo = 'S' AND p.activo = 'S' AND pr.activo = 'S'
                ORDER BY pr.nombre, p.nombre
                """;

        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {

            while (rs.next()) {
                asociaciones.add(new ProductoProveedorDTO(
                        rs.getString("codigo"),
                        rs.getString("nombre_producto"),
                        rs.getLong("id_proveedor"),
                        rs.getString("nombre_proveedor")
                ));
            }
        } catch (SQLException e) {
            throw new RuntimeException("Error listando asociaciones producto-proveedor", e);
        }

        return asociaciones;
    }

    private String mapProveedorError(SQLException e) {
        String message = e.getMessage();
        if (message == null) {
            return "No se pudo completar la operación con proveedores.";
        }

        if (message.contains("ORA-20200")) {
            return "Ya existe un proveedor activo con ese nombre.";
        }
        if (message.contains("ORA-20201")) {
            return "El producto indicado no existe o está inactivo.";
        }
        if (message.contains("ORA-20202")) {
            return "El proveedor indicado no existe o está inactivo.";
        }

        return "No se pudo completar la operación con proveedores.";
    }
}

