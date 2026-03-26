package org.example.db;

import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.SQLException;

public class DatabaseConnection {

    private final static String CONNECT_STRING = "(description= (retry_count=20)(retry_delay=3)(address=(protocol=tcps)(port=1522)(host=adb.sa-saopaulo-1.oraclecloud.com))(connect_data=(service_name=g3cd3c7732a7af0_vzd2hjjab8grjo1o_low.adb.oraclecloud.com))(security=(ssl_server_dn_match=yes)))";
    private static final String URL =
            //"jdbc:oracle:thin:@" + CONNECT_STRING;
            "jdbc:oracle:thin:@//localhost:1521/xe";

    private static final String USER = "USUARIO_PROYECTO";
    //private static final String PASS = "Usr123456789";
    private static final String PASS = "usr123";

    public static Connection getConnection() throws SQLException {
        return DriverManager.getConnection(URL, USER, PASS);
    }
}
