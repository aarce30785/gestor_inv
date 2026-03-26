-- Gestor de inventario


CREATE USER usuario_proyecto IDENTIFIED BY usr123
DEFAULT TABLESPACE users
TEMPORARY TABLESPACE temp
QUOTA UNLIMITED ON users;

GRANT
  CREATE SESSION,
  CREATE TABLE,
  CREATE SEQUENCE,
  CREATE VIEW,
  CREATE PROCEDURE,
  CREATE TRIGGER,
  CREATE TYPE
TO usuario_proyecto;


--Tablas
CREATE TABLE usuario (
    id_usuario       NUMBER PRIMARY KEY,
    username         VARCHAR2(30) UNIQUE NOT NULL,
    password         VARCHAR2(100) NOT NULL,
    rol              VARCHAR2(15) CHECK (rol IN ('ADMIN','OPERADOR')),
    activo            CHAR(1) DEFAULT 'S' CHECK (activo IN ('S','N')),
    fecha_creacion   DATE DEFAULT SYSDATE
);


CREATE TABLE producto (
    id_producto      NUMBER PRIMARY KEY,
    codigo           VARCHAR2(20) UNIQUE NOT NULL,
    nombre           VARCHAR2(100) NOT NULL,
    descripcion      VARCHAR2(200),
    categoria        VARCHAR2(50),
    precio_unitario  NUMBER(10,2) CHECK (precio_unitario >= 0),
    activo           CHAR(1) DEFAULT 'S' CHECK (activo IN ('S','N')),
    fecha_creacion   DATE DEFAULT SYSDATE
);


CREATE TABLE inventario (
    id_inventario    NUMBER PRIMARY KEY,
    id_producto      NUMBER NOT NULL,
    cantidad_actual  NUMBER DEFAULT 0 CHECK (cantidad_actual >= 0),
    stock_minimo     NUMBER DEFAULT 0 CHECK (stock_minimo >= 0),
    fecha_actualizacion DATE DEFAULT SYSDATE,

    CONSTRAINT fk_inv_producto
        FOREIGN KEY (id_producto)
        REFERENCES producto(id_producto)
);


CREATE TABLE movimiento (
    id_movimiento    NUMBER PRIMARY KEY,
    id_producto      NUMBER NOT NULL,
    id_usuario       NUMBER NOT NULL,
    tipo_movimiento  VARCHAR2(10)
        CHECK (tipo_movimiento IN ('ENTRADA','SALIDA','AJUSTE')),
    cantidad         NUMBER CHECK (cantidad > 0),
    fecha_movimiento DATE DEFAULT SYSDATE,
    observacion      VARCHAR2(200),

    CONSTRAINT fk_mov_producto
        FOREIGN KEY (id_producto)
        REFERENCES producto(id_producto),

    CONSTRAINT fk_mov_usuario
        FOREIGN KEY (id_usuario)
        REFERENCES usuario(id_usuario)
);


--Secuencias 
CREATE SEQUENCE seq_usuario START WITH 1 INCREMENT BY 1;
CREATE SEQUENCE seq_producto START WITH 1 INCREMENT BY 1;
CREATE SEQUENCE seq_inventario START WITH 1 INCREMENT BY 1;
CREATE SEQUENCE seq_movimiento START WITH 1 INCREMENT BY 1;


--Paquetes
CREATE OR REPLACE PACKAGE pkg_productos AS

    -- Procedures
    PROCEDURE sp_insertar_producto (
        p_codigo      IN VARCHAR2,
        p_nombre      IN VARCHAR2,
        p_descripcion IN VARCHAR2,
        p_categoria   IN VARCHAR2,
        p_precio      IN NUMBER
    );
    
    PROCEDURE sp_obtener_producto(
        p_codigo IN VARCHAR2,
        p_nombre OUT VARCHAR2,
        p_categoria OUT VARCHAR2,
        p_precio OUT NUMBER
    );

PROCEDURE sp_listar_productos (
        p_busqueda IN VARCHAR2 DEFAULT NULL,
        p_total OUT NUMBER,
    
        p_cod1 OUT VARCHAR2, p_nom1 OUT VARCHAR2, p_cat1 OUT VARCHAR2, p_pre1 OUT NUMBER, p_stock1 OUT NUMBER,
        p_cod2 OUT VARCHAR2, p_nom2 OUT VARCHAR2, p_cat2 OUT VARCHAR2, p_pre2 OUT NUMBER, p_stock2 OUT NUMBER,
        p_cod3 OUT VARCHAR2, p_nom3 OUT VARCHAR2, p_cat3 OUT VARCHAR2, p_pre3 OUT NUMBER, p_stock3 OUT NUMBER,
        p_cod4 OUT VARCHAR2, p_nom4 OUT VARCHAR2, p_cat4 OUT VARCHAR2, p_pre4 OUT NUMBER, p_stock4 OUT NUMBER,
        p_cod5 OUT VARCHAR2, p_nom5 OUT VARCHAR2, p_cat5 OUT VARCHAR2, p_pre5 OUT NUMBER, p_stock5 OUT NUMBER
    );
    
    PROCEDURE sp_editar_producto(
        p_codigo IN VARCHAR2,
        p_nombre IN VARCHAR2,
        p_categoria IN VARCHAR2,
        p_precio IN NUMBER
    );
    
     PROCEDURE sp_eliminar_producto(
        p_codigo IN VARCHAR2
    );

    -- funciones
    FUNCTION fn_codigo_producto_valido (
        p_codigo IN VARCHAR2
    ) RETURN BOOLEAN;

    FUNCTION fn_total_productos_activos
        RETURN NUMBER;

    FUNCTION fn_stock_producto (
        p_codigo_producto IN VARCHAR2
    ) RETURN NUMBER;

END pkg_productos;
/


CREATE OR REPLACE PACKAGE BODY pkg_productos AS

-- Insertar producto

PROCEDURE sp_insertar_producto (
    p_codigo      IN VARCHAR2,
    p_nombre      IN VARCHAR2,
    p_descripcion IN VARCHAR2,
    p_categoria   IN VARCHAR2,
    p_precio      IN NUMBER
) IS
BEGIN
    -- Validación REGEX 
    IF NOT REGEXP_LIKE(p_codigo, '^PRD-[0-9]{3}$') THEN
        RAISE_APPLICATION_ERROR(-20001, 'Código inválido. Formato esperado: PRD-001');
    END IF;

    IF p_precio < 0 THEN
        RAISE_APPLICATION_ERROR(-20002, 'El precio no puede ser negativo');
    END IF;

    INSERT INTO producto (
        id_producto, codigo, nombre, descripcion, categoria, precio_unitario, activo
    ) VALUES (
        seq_producto.NEXTVAL,
        p_codigo,
        p_nombre,
        p_descripcion,
        p_categoria,
        p_precio,
        'S'
    );

EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
        RAISE_APPLICATION_ERROR(-20003, 'Ya existe un producto con ese código');
    WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-20099, 'Error al insertar producto');
END sp_insertar_producto;


PROCEDURE sp_obtener_producto(
    p_codigo IN VARCHAR2,
    p_nombre OUT VARCHAR2,
    p_categoria OUT VARCHAR2,
    p_precio OUT NUMBER
) IS
BEGIN
    SELECT nombre, categoria, precio_unitario
    INTO p_nombre, p_categoria, p_precio
    FROM producto
    WHERE codigo = p_codigo;
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        p_nombre := NULL;
        p_categoria := NULL;
        p_precio := NULL;
END sp_obtener_producto;

-- Listar producto con cursor explicito
PROCEDURE sp_listar_productos (
    p_busqueda IN VARCHAR2 DEFAULT NULL,
    p_total OUT NUMBER,

    p_cod1 OUT VARCHAR2, p_nom1 OUT VARCHAR2, p_cat1 OUT VARCHAR2, p_pre1 OUT NUMBER, p_stock1 OUT NUMBER,
    p_cod2 OUT VARCHAR2, p_nom2 OUT VARCHAR2, p_cat2 OUT VARCHAR2, p_pre2 OUT NUMBER, p_stock2 OUT NUMBER,
    p_cod3 OUT VARCHAR2, p_nom3 OUT VARCHAR2, p_cat3 OUT VARCHAR2, p_pre3 OUT NUMBER, p_stock3 OUT NUMBER,
    p_cod4 OUT VARCHAR2, p_nom4 OUT VARCHAR2, p_cat4 OUT VARCHAR2, p_pre4 OUT NUMBER, p_stock4 OUT NUMBER,
    p_cod5 OUT VARCHAR2, p_nom5 OUT VARCHAR2, p_cat5 OUT VARCHAR2, p_pre5 OUT NUMBER, p_stock5 OUT NUMBER
) IS
    v_busqueda VARCHAR2(100);

    CURSOR c_prod IS
        SELECT codigo, nombre, categoria, precio_unitario
        FROM producto
        WHERE activo = 'S'
          AND (
                v_busqueda IS NULL
                OR TO_CHAR(codigo) LIKE '%' || UPPER(v_busqueda) || '%'
                OR UPPER(nombre) LIKE '%' || UPPER(v_busqueda) || '%'
              )
        ORDER BY fecha_creacion;

    v_cod producto.codigo%TYPE;
    v_nom producto.nombre%TYPE;
    v_cat producto.categoria%TYPE;
    v_pre producto.precio_unitario%TYPE;
    v_stock NUMBER;

    v_cont NUMBER := 0;

BEGIN
    IF TRIM(p_busqueda) IS NULL THEN
        v_busqueda := NULL;
    ELSE
        v_busqueda := p_busqueda;
    END IF;

    p_total := 0;
    p_cod1 := NULL; p_nom1 := NULL; p_cat1 := NULL; p_pre1 := NULL; p_stock1 := NULL;
    p_cod2 := NULL; p_nom2 := NULL; p_cat2 := NULL; p_pre2 := NULL; p_stock2 := NULL;
    p_cod3 := NULL; p_nom3 := NULL; p_cat3 := NULL; p_pre3 := NULL; p_stock3 := NULL;
    p_cod4 := NULL; p_nom4 := NULL; p_cat4 := NULL; p_pre4 := NULL; p_stock4 := NULL;
    p_cod5 := NULL; p_nom5 := NULL; p_cat5 := NULL; p_pre5 := NULL; p_stock5 := NULL;

    OPEN c_prod;
    LOOP
        FETCH c_prod INTO v_cod, v_nom, v_cat, v_pre;
        EXIT WHEN c_prod%NOTFOUND OR v_cont = 5;

        v_cont := v_cont + 1;
        p_total := v_cont;

        v_stock := fn_stock_producto(v_cod); 

        CASE v_cont
            WHEN 1 THEN p_cod1 := v_cod; p_nom1 := v_nom; p_cat1 := v_cat; p_pre1 := v_pre; p_stock1 := v_stock;
            WHEN 2 THEN p_cod2 := v_cod; p_nom2 := v_nom; p_cat2 := v_cat; p_pre2 := v_pre; p_stock2 := v_stock;
            WHEN 3 THEN p_cod3 := v_cod; p_nom3 := v_nom; p_cat3 := v_cat; p_pre3 := v_pre; p_stock3 := v_stock;
            WHEN 4 THEN p_cod4 := v_cod; p_nom4 := v_nom; p_cat4 := v_cat; p_pre4 := v_pre; p_stock4 := v_stock;
            WHEN 5 THEN p_cod5 := v_cod; p_nom5 := v_nom; p_cat5 := v_cat; p_pre5 := v_pre; p_stock5 := v_stock;
        END CASE;
    END LOOP;
    CLOSE c_prod;

EXCEPTION
    WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-20100, 'Error al listar productos');
END sp_listar_productos;


PROCEDURE sp_editar_producto(
    p_codigo IN VARCHAR2,
    p_nombre IN VARCHAR2,
    p_categoria IN VARCHAR2,
    p_precio IN NUMBER
) IS
BEGIN
    UPDATE producto
    SET nombre = p_nombre,
        categoria = p_categoria,
        precio_unitario = p_precio
    WHERE codigo = p_codigo;

    IF SQL%ROWCOUNT = 0 THEN
        RAISE_APPLICATION_ERROR(-20101, 'Producto no encontrado para actualizar');
    END IF;
END sp_editar_producto;

PROCEDURE sp_eliminar_producto(p_codigo IN VARCHAR2) IS
BEGIN
    UPDATE producto
    SET activo = 'N'
    WHERE codigo = p_codigo;
END;

--Funciones
FUNCTION fn_codigo_producto_valido (
    p_codigo IN VARCHAR2
) RETURN BOOLEAN
IS
BEGIN
    RETURN REGEXP_LIKE(p_codigo, '^PRD-[0-9]{3}$');
END;


FUNCTION fn_total_productos_activos
RETURN NUMBER
IS
    v_total NUMBER;
BEGIN
    SELECT COUNT(*)
    INTO v_total
    FROM producto
    WHERE activo = 'S';

    RETURN v_total;
END;


FUNCTION fn_stock_producto (
    p_codigo_producto IN VARCHAR2
) RETURN NUMBER
IS
    v_stock NUMBER;
BEGIN
    SELECT i.cantidad_actual
    INTO v_stock
    FROM inventario i
    JOIN producto p ON p.id_producto = i.id_producto
    WHERE p.codigo = p_codigo_producto
      AND p.activo = 'S';

    RETURN v_stock;

EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RETURN -1;
    WHEN OTHERS THEN
        RETURN -2;
END;

END pkg_productos;
/


CREATE OR REPLACE PACKAGE pkg_movimientos AS

    -- Registrar movimiento de inventario
    PROCEDURE sp_registrar_movimiento (
        p_codigo_producto IN VARCHAR2,
        p_usuario         IN VARCHAR2, -- username
        p_tipo            IN VARCHAR2,
        p_cantidad        IN NUMBER,
        p_observacion     IN VARCHAR2,
        p_stock_minimo    IN NUMBER DEFAULT NULL  -- nuevo parámetro opcional
    );

    -- Listar últimos movimientos (máx 10)
    PROCEDURE sp_listar_movimientos (
        p_total OUT NUMBER,

        p_prod1 OUT VARCHAR2, p_tipo1 OUT VARCHAR2, p_cant1 OUT NUMBER, p_fecha1 OUT DATE,
        p_prod2 OUT VARCHAR2, p_tipo2 OUT VARCHAR2, p_cant2 OUT NUMBER, p_fecha2 OUT DATE,
        p_prod3 OUT VARCHAR2, p_tipo3 OUT VARCHAR2, p_cant3 OUT NUMBER, p_fecha3 OUT DATE,
        p_prod4 OUT VARCHAR2, p_tipo4 OUT VARCHAR2, p_cant4 OUT NUMBER, p_fecha4 OUT DATE,
        p_prod5 OUT VARCHAR2, p_tipo5 OUT VARCHAR2, p_cant5 OUT NUMBER, p_fecha5 OUT DATE
    );

END pkg_movimientos;
/



CREATE OR REPLACE PACKAGE BODY pkg_movimientos AS


-- Registrar movimiento

PROCEDURE sp_registrar_movimiento (
    p_codigo_producto IN VARCHAR2,
    p_usuario         IN VARCHAR2, -- username
    p_tipo            IN VARCHAR2,
    p_cantidad        IN NUMBER,
    p_observacion     IN VARCHAR2,
    p_stock_minimo    IN NUMBER DEFAULT NULL  -- nuevo parámetro opcional
) IS
    v_id_producto producto.id_producto%TYPE;
    v_id_usuario  usuario.id_usuario%TYPE;
    v_stock       inventario.cantidad_actual%TYPE;
BEGIN
    -- Validaciones
    IF p_cantidad <= 0 THEN
        RAISE_APPLICATION_ERROR(-20001, 'La cantidad debe ser mayor a cero');
    END IF;

    IF p_tipo NOT IN ('ENTRADA','SALIDA','AJUSTE') THEN
        RAISE_APPLICATION_ERROR(-20001, 'Tipo de movimiento inválido');
    END IF;

    -- Producto
    SELECT id_producto
    INTO v_id_producto
    FROM producto
    WHERE codigo = p_codigo_producto
      AND activo = 'S';

    -- Usuario por username
    SELECT id_usuario
    INTO v_id_usuario
    FROM usuario
    WHERE username = p_usuario
      AND activo = 'S';

    -- Stock actual
    SELECT cantidad_actual
    INTO v_stock
    FROM inventario
    WHERE id_producto = v_id_producto
    FOR UPDATE;

    IF p_tipo = 'SALIDA' AND v_stock < p_cantidad THEN
        RAISE_APPLICATION_ERROR(-20001, 'Stock insuficiente');
    END IF;

    -- Insertar movimiento
    INSERT INTO movimiento (
        id_movimiento,
        id_producto,
        id_usuario,
        tipo_movimiento,
        cantidad,
        observacion,
        fecha_movimiento
    ) VALUES (
        seq_movimiento.NEXTVAL,
        v_id_producto,
        v_id_usuario,
        p_tipo,
        p_cantidad,
        p_observacion,
        SYSDATE
    );

    -- Actualizar inventario
    IF p_tipo = 'ENTRADA' THEN
        UPDATE inventario
        SET cantidad_actual = cantidad_actual + p_cantidad,
            fecha_actualizacion = SYSDATE,
            stock_minimo = NVL(p_stock_minimo, stock_minimo)
        WHERE id_producto = v_id_producto;

    ELSIF p_tipo = 'SALIDA' THEN
        UPDATE inventario
        SET cantidad_actual = cantidad_actual - p_cantidad,
            fecha_actualizacion = SYSDATE,
            stock_minimo = NVL(p_stock_minimo, stock_minimo)
        WHERE id_producto = v_id_producto;

    ELSE -- AJUSTE
        UPDATE inventario
        SET cantidad_actual = p_cantidad,
            fecha_actualizacion = SYSDATE,
            stock_minimo = NVL(p_stock_minimo, stock_minimo)
        WHERE id_producto = v_id_producto;
    END IF;

EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RAISE_APPLICATION_ERROR(-20002, 'Producto o usuario no existe');
    WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-20003, 'Error al registrar movimiento');
END sp_registrar_movimiento;



-- Listar moviemientos con cursor

PROCEDURE sp_listar_movimientos (
    p_total OUT NUMBER,

    p_prod1 OUT VARCHAR2, p_tipo1 OUT VARCHAR2, p_cant1 OUT NUMBER, p_fecha1 OUT DATE,
    p_prod2 OUT VARCHAR2, p_tipo2 OUT VARCHAR2, p_cant2 OUT NUMBER, p_fecha2 OUT DATE,
    p_prod3 OUT VARCHAR2, p_tipo3 OUT VARCHAR2, p_cant3 OUT NUMBER, p_fecha3 OUT DATE,
    p_prod4 OUT VARCHAR2, p_tipo4 OUT VARCHAR2, p_cant4 OUT NUMBER, p_fecha4 OUT DATE,
    p_prod5 OUT VARCHAR2, p_tipo5 OUT VARCHAR2, p_cant5 OUT NUMBER, p_fecha5 OUT DATE
) IS
    CURSOR c_mov IS
        SELECT p.codigo, m.tipo_movimiento, m.cantidad, m.fecha_movimiento
        FROM movimiento m
        JOIN producto p ON p.id_producto = m.id_producto
        ORDER BY m.fecha_movimiento DESC;

    v_cod  producto.codigo%TYPE;
    v_tipo movimiento.tipo_movimiento%TYPE;
    v_cant movimiento.cantidad%TYPE;
    v_fecha movimiento.fecha_movimiento%TYPE;

    v_cont NUMBER := 0;
BEGIN
    p_total := 0;

    OPEN c_mov;
    LOOP
        FETCH c_mov INTO v_cod, v_tipo, v_cant, v_fecha;
        EXIT WHEN c_mov%NOTFOUND OR v_cont = 5;

        v_cont := v_cont + 1;
        p_total := v_cont;

        CASE v_cont
            WHEN 1 THEN p_prod1 := v_cod; p_tipo1 := v_tipo; p_cant1 := v_cant; p_fecha1 := v_fecha;
            WHEN 2 THEN p_prod2 := v_cod; p_tipo2 := v_tipo; p_cant2 := v_cant; p_fecha2 := v_fecha;
            WHEN 3 THEN p_prod3 := v_cod; p_tipo3 := v_tipo; p_cant3 := v_cant; p_fecha3 := v_fecha;
            WHEN 4 THEN p_prod4 := v_cod; p_tipo4 := v_tipo; p_cant4 := v_cant; p_fecha4 := v_fecha;
            WHEN 5 THEN p_prod5 := v_cod; p_tipo5 := v_tipo; p_cant5 := v_cant; p_fecha5 := v_fecha;
        END CASE;
    END LOOP;
    CLOSE c_mov;

EXCEPTION
    WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-20003, 'Error al listar movimientos');
END sp_listar_movimientos;

END pkg_movimientos;
/

CREATE OR REPLACE PACKAGE pkg_reportes AS

    PROCEDURE sp_buscar_productos (
        p_categoria IN VARCHAR2,
        p_min_precio IN NUMBER,
        p_max_precio IN NUMBER,

        p_total OUT NUMBER,
        p_cod1 OUT VARCHAR2, p_nom1 OUT VARCHAR2, p_pre1 OUT NUMBER,
        p_cod2 OUT VARCHAR2, p_nom2 OUT VARCHAR2, p_pre2 OUT NUMBER,
        p_cod3 OUT VARCHAR2, p_nom3 OUT VARCHAR2, p_pre3 OUT NUMBER,
        p_cod4 OUT VARCHAR2, p_nom4 OUT VARCHAR2, p_pre4 OUT NUMBER,
        p_cod5 OUT VARCHAR2, p_nom5 OUT VARCHAR2, p_pre5 OUT NUMBER
    );

END pkg_reportes;
/

CREATE OR REPLACE PACKAGE BODY pkg_reportes AS

PROCEDURE sp_buscar_productos (
    p_categoria IN VARCHAR2,
    p_min_precio IN NUMBER,
    p_max_precio IN NUMBER,

    p_total OUT NUMBER,
    p_cod1 OUT VARCHAR2, p_nom1 OUT VARCHAR2, p_pre1 OUT NUMBER,
    p_cod2 OUT VARCHAR2, p_nom2 OUT VARCHAR2, p_pre2 OUT NUMBER,
    p_cod3 OUT VARCHAR2, p_nom3 OUT VARCHAR2, p_pre3 OUT NUMBER,
    p_cod4 OUT VARCHAR2, p_nom4 OUT VARCHAR2, p_pre4 OUT NUMBER,
    p_cod5 OUT VARCHAR2, p_nom5 OUT VARCHAR2, p_pre5 OUT NUMBER
) IS

    v_sql   VARCHAR2(1000);
    CURSOR c_dyn IS
        SELECT codigo, nombre, precio_unitario
        FROM producto
        WHERE activo = 'S';

    TYPE ref_cursor IS REF CURSOR;
    c_ref ref_cursor;

    v_cod producto.codigo%TYPE;
    v_nom producto.nombre%TYPE;
    v_pre producto.precio_unitario%TYPE;

    v_cont NUMBER := 0;

BEGIN
    -- SQL base
    v_sql := '
        SELECT codigo, nombre, precio_unitario
        FROM producto
        WHERE activo = ''S''
    ';

    -- Filtro dinámico
    IF p_categoria IS NOT NULL THEN
        v_sql := v_sql || ' AND categoria = :cat';
    END IF;

    IF p_min_precio IS NOT NULL THEN
        v_sql := v_sql || ' AND precio_unitario >= :minp';
    END IF;

    IF p_max_precio IS NOT NULL THEN
        v_sql := v_sql || ' AND precio_unitario <= :maxp';
    END IF;

    v_sql := v_sql || ' ORDER BY nombre';

    -- Abrir cursor 
    IF p_categoria IS NOT NULL AND p_min_precio IS NOT NULL AND p_max_precio IS NOT NULL THEN
        OPEN c_ref FOR v_sql USING p_categoria, p_min_precio, p_max_precio;

    ELSIF p_categoria IS NOT NULL AND p_min_precio IS NOT NULL THEN
        OPEN c_ref FOR v_sql USING p_categoria, p_min_precio;

    ELSIF p_categoria IS NOT NULL THEN
        OPEN c_ref FOR v_sql USING p_categoria;

    ELSE
        OPEN c_ref FOR v_sql;
    END IF;

    p_total := 0;

    LOOP
        FETCH c_ref INTO v_cod, v_nom, v_pre;
        EXIT WHEN c_ref%NOTFOUND OR v_cont = 5;

        v_cont := v_cont + 1;
        p_total := v_cont;

        CASE v_cont
            WHEN 1 THEN p_cod1 := v_cod; p_nom1 := v_nom; p_pre1 := v_pre;
            WHEN 2 THEN p_cod2 := v_cod; p_nom2 := v_nom; p_pre2 := v_pre;
            WHEN 3 THEN p_cod3 := v_cod; p_nom3 := v_nom; p_pre3 := v_pre;
            WHEN 4 THEN p_cod4 := v_cod; p_nom4 := v_nom; p_pre4 := v_pre;
            WHEN 5 THEN p_cod5 := v_cod; p_nom5 := v_nom; p_pre5 := v_pre;
        END CASE;
    END LOOP;

    CLOSE c_ref;

EXCEPTION
    WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-20030, 'Error en búsqueda dinámica de productos');
END sp_buscar_productos;

END pkg_reportes;
/


CREATE OR REPLACE PACKAGE pkg_reportes_stock AS

    PROCEDURE sp_reporte_stock_minimo (
        p_total OUT NUMBER,

        p_cod1 OUT VARCHAR2, p_nom1 OUT VARCHAR2, p_cant1 OUT NUMBER, p_min1 OUT NUMBER,
        p_cod2 OUT VARCHAR2, p_nom2 OUT VARCHAR2, p_cant2 OUT NUMBER, p_min2 OUT NUMBER,
        p_cod3 OUT VARCHAR2, p_nom3 OUT VARCHAR2, p_cant3 OUT NUMBER, p_min3 OUT NUMBER,
        p_cod4 OUT VARCHAR2, p_nom4 OUT VARCHAR2, p_cant4 OUT NUMBER, p_min4 OUT NUMBER,
        p_cod5 OUT VARCHAR2, p_nom5 OUT VARCHAR2, p_cant5 OUT NUMBER, p_min5 OUT NUMBER
    );

END pkg_reportes_stock;
/


CREATE OR REPLACE PACKAGE BODY pkg_reportes_stock AS

PROCEDURE sp_reporte_stock_minimo (
    p_total OUT NUMBER,

    p_cod1 OUT VARCHAR2, p_nom1 OUT VARCHAR2, p_cant1 OUT NUMBER, p_min1 OUT NUMBER,
    p_cod2 OUT VARCHAR2, p_nom2 OUT VARCHAR2, p_cant2 OUT NUMBER, p_min2 OUT NUMBER,
    p_cod3 OUT VARCHAR2, p_nom3 OUT VARCHAR2, p_cant3 OUT NUMBER, p_min3 OUT NUMBER,
    p_cod4 OUT VARCHAR2, p_nom4 OUT VARCHAR2, p_cant4 OUT NUMBER, p_min4 OUT NUMBER,
    p_cod5 OUT VARCHAR2, p_nom5 OUT VARCHAR2, p_cant5 OUT NUMBER, p_min5 OUT NUMBER
) IS

    CURSOR c_stock IS
        SELECT p.codigo,
               p.nombre,
               i.cantidad_actual,
               i.stock_minimo
        FROM inventario i
        JOIN producto p ON p.id_producto = i.id_producto
        WHERE i.cantidad_actual <= i.stock_minimo
          AND p.activo = 'S'
        ORDER BY i.cantidad_actual ASC;

    v_cod  producto.codigo%TYPE;
    v_nom  producto.nombre%TYPE;
    v_cant inventario.cantidad_actual%TYPE;
    v_min  inventario.stock_minimo%TYPE;

    v_cont NUMBER := 0;

BEGIN
    p_total := 0;

    OPEN c_stock;
    LOOP
        FETCH c_stock INTO v_cod, v_nom, v_cant, v_min;
        EXIT WHEN c_stock%NOTFOUND OR v_cont = 5;

        v_cont := v_cont + 1;
        p_total := v_cont;

        CASE v_cont
            WHEN 1 THEN p_cod1 := v_cod; p_nom1 := v_nom; p_cant1 := v_cant; p_min1 := v_min;
            WHEN 2 THEN p_cod2 := v_cod; p_nom2 := v_nom; p_cant2 := v_cant; p_min2 := v_min;
            WHEN 3 THEN p_cod3 := v_cod; p_nom3 := v_nom; p_cant3 := v_cant; p_min3 := v_min;
            WHEN 4 THEN p_cod4 := v_cod; p_nom4 := v_nom; p_cant4 := v_cant; p_min4 := v_min;
            WHEN 5 THEN p_cod5 := v_cod; p_nom5 := v_nom; p_cant5 := v_cant; p_min5 := v_min;
        END CASE;
    END LOOP;

    CLOSE c_stock;

EXCEPTION
    WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-20030, 'Error al generar reporte de stock mínimo');
END sp_reporte_stock_minimo;

END pkg_reportes_stock;
/


CREATE OR REPLACE PACKAGE pkg_login AS

    PROCEDURE sp_login (
        p_username IN VARCHAR2,
        p_password IN VARCHAR2,
        p_rol      OUT VARCHAR2
    );

END pkg_login;
/


CREATE OR REPLACE PACKAGE BODY pkg_login AS

PROCEDURE sp_login (
    p_username IN VARCHAR2,
    p_password IN VARCHAR2,
    p_rol      OUT VARCHAR2
) IS
    v_count NUMBER;
BEGIN
    -- Validar existencia y estado
    SELECT COUNT(*)
    INTO v_count
    FROM usuario
    WHERE username = p_username
      AND password = p_password
      AND activo = 'S';

    IF v_count = 0 THEN
        RAISE_APPLICATION_ERROR(-20001, 'Usuario o contraseña incorrectos');
    END IF;

    -- Obtener rol
    SELECT rol
    INTO p_rol
    FROM usuario
    WHERE username = p_username
      AND password = p_password
      AND activo = 'S';

EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RAISE_APPLICATION_ERROR(-20001, 'Usuario no encontrado');
    WHEN TOO_MANY_ROWS THEN
        RAISE_APPLICATION_ERROR(-20002, 'Datos duplicados de usuario');
    WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-20003, 'Error en el proceso de login');
END sp_login;

END pkg_login;
/


--Triggers
CREATE OR REPLACE TRIGGER trg_crear_inventario
AFTER INSERT ON producto
FOR EACH ROW
BEGIN
    INSERT INTO inventario (
        id_inventario,
        id_producto,
        cantidad_actual,
        stock_minimo,
        fecha_actualizacion
    ) VALUES (
        seq_inventario.NEXTVAL,
        :NEW.id_producto,
        0,
        0,
        SYSDATE
    );
EXCEPTION
    WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(
            -20030,
            'Error al crear inventario automático para el producto'
        );
END;
/





--Pruebas

--Limpiar BD
DELETE FROM movimiento;
DELETE FROM inventario;
DELETE FROM producto;
DELETE FROM usuario;

COMMIT;


--Crear usuarios
INSERT INTO usuario
VALUES (seq_usuario.NEXTVAL, 'admin', 'admin123', 'ADMIN', 'S', SYSDATE);

INSERT INTO usuario
VALUES (seq_usuario.NEXTVAL, 'operador', 'op123', 'OPERADOR', 'S', SYSDATE);

COMMIT;


--Insertar productos
BEGIN
    pkg_productos.sp_insertar_producto(
        'PRD-001', 'Mouse USB', 'Mouse óptico', 'Periféricos', 5500
    );

    pkg_productos.sp_insertar_producto(
        'PRD-002', 'Teclado Mecánico', 'Switch azul', 'Periféricos', 22000
    );

    pkg_productos.sp_insertar_producto(
        'PRD-003', 'Monitor 24"', 'Full HD', 'Pantallas', 95000
    );
END;
/


--Verificar inventario automatico
SELECT p.codigo, i.cantidad_actual, i.stock_minimo
FROM inventario i
JOIN producto p ON p.id_producto = i.id_producto;

--Registrar movimientos
BEGIN
    pkg_movimientos.sp_registrar_movimiento(
        'PRD-001', 'admin', 'ENTRADA', 50, 'Compra inicial'
    );

    pkg_movimientos.sp_registrar_movimiento(
        'PRD-002', 'admin', 'ENTRADA', 20, 'Compra proveedor'
    );
END;
/

--valida
BEGIN
    pkg_movimientos.sp_registrar_movimiento(
        'PRD-001', 'operador', 'SALIDA', 10, 'Venta'
    );
END;
/

--invalida
BEGIN
    pkg_movimientos.sp_registrar_movimiento(
        'PRD-002', 'operador', 'SALIDA', 999, 'Prueba error'
    );
END;
/

--ajustar stock minimo
UPDATE inventario
SET stock_minimo = 15
WHERE id_producto = (
    SELECT id_producto FROM producto WHERE codigo = 'PRD-001'
);

COMMIT;


--reporte stock minimo
DECLARE
    v_total NUMBER;

    c1 VARCHAR2(20); n1 VARCHAR2(100); q1 NUMBER; m1 NUMBER;
    c2 VARCHAR2(20); n2 VARCHAR2(100); q2 NUMBER; m2 NUMBER;
    c3 VARCHAR2(20); n3 VARCHAR2(100); q3 NUMBER; m3 NUMBER;
    c4 VARCHAR2(20); n4 VARCHAR2(100); q4 NUMBER; m4 NUMBER;
    c5 VARCHAR2(20); n5 VARCHAR2(100); q5 NUMBER; m5 NUMBER;
BEGIN
    pkg_reportes_stock.sp_reporte_stock_minimo(
        v_total,
        c1,n1,q1,m1,
        c2,n2,q2,m2,
        c3,n3,q3,m3,
        c4,n4,q4,m4,
        c5,n5,q5,m5
    );

    DBMS_OUTPUT.PUT_LINE('Productos críticos: ' || v_total);
    DBMS_OUTPUT.PUT_LINE(c1 || ' - ' || n1 || ' (' || q1 || '/' || m1 || ')');
END;
/


--probar login
DECLARE
    v_rol VARCHAR2(20);
BEGIN
    pkg_login.sp_login('admin','admin123',v_rol);
    DBMS_OUTPUT.PUT_LINE('Login OK. Rol: ' || v_rol);
END;
/

--invalido
DECLARE
    v_rol VARCHAR2(20);
BEGIN
    pkg_login.sp_login('admin','1234',v_rol);
    DBMS_OUTPUT.PUT_LINE('Login OK. Rol: ' || v_rol);
END;
/

-- PROBAR LISTADO DE PRODUCTOS CON BÚSQUEDA
DECLARE
    v_total NUMBER;
    
    c1 VARCHAR2(20); n1 VARCHAR2(100); cat1 VARCHAR2(50); p1 NUMBER;
    c2 VARCHAR2(20); n2 VARCHAR2(100); cat2 VARCHAR2(50); p2 NUMBER;
    c3 VARCHAR2(20); n3 VARCHAR2(100); cat3 VARCHAR2(50); p3 NUMBER;
    c4 VARCHAR2(20); n4 VARCHAR2(100); cat4 VARCHAR2(50); p4 NUMBER;
    c5 VARCHAR2(20); n5 VARCHAR2(100); cat5 VARCHAR2(50); p5 NUMBER;
BEGIN
    -- Cambiá 'TECLADO' por la palabra que quieras buscar
    pkg_productos.sp_listar_productos(
        p_busqueda => 'TECLADO',  
        p_total => v_total,
        p_cod1 => c1, p_nom1 => n1, p_cat1 => cat1, p_pre1 => p1,
        p_cod2 => c2, p_nom2 => n2, p_cat2 => cat2, p_pre2 => p2,
        p_cod3 => c3, p_nom3 => n3, p_cat3 => cat3, p_pre3 => p3,
        p_cod4 => c4, p_nom4 => n4, p_cat4 => cat4, p_pre4 => p4,
        p_cod5 => c5, p_nom5 => n5, p_cat5 => cat5, p_pre5 => p5
    );

    DBMS_OUTPUT.PUT_LINE('Total productos encontrados: ' || v_total);

    IF v_total >= 1 THEN DBMS_OUTPUT.PUT_LINE(c1 || ' - ' || n1 || ' - ' || cat1 || ' - ?' || p1); END IF;
    IF v_total >= 2 THEN DBMS_OUTPUT.PUT_LINE(c2 || ' - ' || n2 || ' - ' || cat2 || ' - ?' || p2); END IF;
    IF v_total >= 3 THEN DBMS_OUTPUT.PUT_LINE(c3 || ' - ' || n3 || ' - ' || cat3 || ' - ?' || p3); END IF;
    IF v_total >= 4 THEN DBMS_OUTPUT.PUT_LINE(c4 || ' - ' || n4 || ' - ' || cat4 || ' - ?' || p4); END IF;
    IF v_total >= 5 THEN DBMS_OUTPUT.PUT_LINE(c5 || ' - ' || n5 || ' - ' || cat5 || ' - ?' || p5); END IF;
END;
/


BEGIN
    IF pkg_productos.fn_codigo_producto_valido('PRD-001') THEN
        DBMS_OUTPUT.PUT_LINE('Código OK');
    ELSE
        DBMS_OUTPUT.PUT_LINE('Código inválido');
    END IF;
END;
/

DECLARE
    v_total NUMBER;
BEGIN
    v_total := pkg_productos.fn_total_productos_activos;
    DBMS_OUTPUT.PUT_LINE('Productos activos: ' || v_total);
END;
/



DECLARE
    v_stock NUMBER;
BEGIN
    v_stock := pkg_productos.fn_stock_producto('PRD-001');

    IF v_stock >= 0 THEN
        DBMS_OUTPUT.PUT_LINE('Stock actual: ' || v_stock);
    ELSE
        DBMS_OUTPUT.PUT_LINE('Producto no encontrado');
    END IF;
END;
/



SELECT argument_name, data_type, in_out, position
FROM user_arguments
WHERE object_name = 'SP_LISTAR_MOVIMIENTOS'
ORDER BY position;


SELECT id_usuario
FROM usuario
WHERE username = 'admin';


--EXECUTE INMEDIATE? 




