package org.example.dao;

import org.example.db.DatabaseConnection;
import org.springframework.stereotype.Repository;

import java.sql.CallableStatement;
import java.sql.Connection;
import java.sql.Types;

@Repository
public class LoginDAO {

    public String login(String username, String password) {

        String sql = "{ call pkg_login.sp_login(?, ?, ?) }";

        try (Connection conn = DatabaseConnection.getConnection();
             CallableStatement cs = conn.prepareCall(sql)) {

            cs.setString(1, username);
            cs.setString(2, password);
            cs.registerOutParameter(3, Types.VARCHAR);

            cs.execute();

            String rol = cs.getString(3);
            if (rol == null || rol.trim().isEmpty()) {
                throw new RuntimeException("Credenciales invalidas.");
            }

            return rol; // ROL

        } catch (Exception e) {
            throw new RuntimeException(e.getMessage());
        }
    }
}
