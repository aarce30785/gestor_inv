package org.example;


import org.example.db.DatabaseConnection;
import java.sql.Connection;

public class TestConexion {
    public static void main(String[] args) {
        try (Connection conn = DatabaseConnection.getConnection()) {
            System.out.println("Conectado a Oracle ");
        } catch (Exception e) {
            e.printStackTrace();
        }
    }
}
