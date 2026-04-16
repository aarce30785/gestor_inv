-- ============================================================
-- PARTE 1: Ejecutar como SYS o SYSTEM
-- ============================================================

-- Eliminar usuario si ya existe
BEGIN
    EXECUTE IMMEDIATE 'DROP USER usuario_proyecto CASCADE';
EXCEPTION
    WHEN OTHERS THEN NULL; -- Ignorar si no existe
END;
/

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

-- Permisos sobre paquetes del sistema (necesarios para hash de passwords y sesiones)
GRANT EXECUTE ON SYS.DBMS_CRYPTO  TO usuario_proyecto;
GRANT EXECUTE ON SYS.DBMS_SESSION TO usuario_proyecto;

-- ============================================================
-- PARTE 2: Conectar como usuario_proyecto y ejecutar el resto
-- ============================================================

-- Modelo de datos principal del sistema:
-- - usuario: autenticacion y roles
-- - producto/inventario/movimiento: catalogo y control de stock
-- - proveedor/producto_proveedor/compra_proveedor: compras y abastecimiento
-- - historial_stock/historial_producto: auditoria de cambios

-- Tablas
CREATE TABLE usuario (
    id_usuario       NUMBER PRIMARY KEY,
    username         VARCHAR2(30) UNIQUE NOT NULL,
    password         VARCHAR2(100) NOT NULL,
    rol              VARCHAR2(15) CHECK (rol IN ('ADMIN','OPERADOR')),
    activo            CHAR(1) DEFAULT 'S' CHECK (activo IN ('S','N')),
    fecha_creacion   DATE DEFAULT SYSDATE
);


-- Catalogo de productos administrados por el sistema
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


-- Estado de stock actual y minimo por producto
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


-- Movimientos de inventario (entradas, salidas y ajustes)
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

-- Maestro de proveedores
CREATE TABLE proveedor (
    id_proveedor      NUMBER PRIMARY KEY,
    nombre            VARCHAR2(120) NOT NULL,
    telefono          VARCHAR2(30),
    email             VARCHAR2(120),
    activo            CHAR(1) DEFAULT 'S' CHECK (activo IN ('S','N')),
    fecha_creacion    DATE DEFAULT SYSDATE,
    CONSTRAINT uk_proveedor_nombre UNIQUE (nombre)
);

-- Relacion N:M entre productos y proveedores habilitados
CREATE TABLE producto_proveedor (
    id_producto       NUMBER NOT NULL,
    id_proveedor      NUMBER NOT NULL,
    activo            CHAR(1) DEFAULT 'S' CHECK (activo IN ('S','N')),
    fecha_asociacion  DATE DEFAULT SYSDATE,
    CONSTRAINT pk_producto_proveedor PRIMARY KEY (id_producto, id_proveedor),
    CONSTRAINT fk_pp_producto FOREIGN KEY (id_producto) REFERENCES producto(id_producto),
    CONSTRAINT fk_pp_proveedor FOREIGN KEY (id_proveedor) REFERENCES proveedor(id_proveedor)
);

-- Compras realizadas a proveedores (impacta stock via pkg_movimientos)
CREATE TABLE compra_proveedor (
    id_compra         NUMBER PRIMARY KEY,
    id_producto       NUMBER NOT NULL,
    id_proveedor      NUMBER NOT NULL,
    id_usuario        NUMBER NOT NULL,
    cantidad          NUMBER NOT NULL CHECK (cantidad > 0),
    costo_unitario    NUMBER(10,2) NOT NULL CHECK (costo_unitario >= 0),
    observacion       VARCHAR2(200),
    fecha_compra      DATE DEFAULT SYSDATE,
    CONSTRAINT fk_compra_producto FOREIGN KEY (id_producto) REFERENCES producto(id_producto),
    CONSTRAINT fk_compra_proveedor FOREIGN KEY (id_proveedor) REFERENCES proveedor(id_proveedor),
    CONSTRAINT fk_compra_usuario FOREIGN KEY (id_usuario) REFERENCES usuario(id_usuario)
);

-- Bitacora de cambios de stock y stock minimo
CREATE TABLE historial_stock (
    id_historial         NUMBER PRIMARY KEY,
    id_inventario        NUMBER NOT NULL,
    cantidad_anterior    NUMBER,
    cantidad_nueva       NUMBER,
    stock_minimo_anterior NUMBER,
    stock_minimo_nuevo   NUMBER,
    usuario_responsable  VARCHAR2(30),
    fecha_cambio         DATE DEFAULT SYSDATE,
    origen               VARCHAR2(40),
    CONSTRAINT fk_historial_inventario FOREIGN KEY (id_inventario) REFERENCES inventario(id_inventario)
);

-- Bitacora de altas/ediciones/desactivaciones de productos
CREATE TABLE historial_producto (
    id_historial_producto NUMBER PRIMARY KEY,
    id_producto           NUMBER NOT NULL,
    codigo                VARCHAR2(20),
    tipo_operacion        VARCHAR2(20) NOT NULL,
    nombre_anterior       VARCHAR2(100),
    nombre_nuevo          VARCHAR2(100),
    descripcion_anterior  VARCHAR2(200),
    descripcion_nueva     VARCHAR2(200),
    categoria_anterior    VARCHAR2(50),
    categoria_nueva       VARCHAR2(50),
    precio_anterior       NUMBER(10,2),
    precio_nuevo          NUMBER(10,2),
    activo_anterior       CHAR(1),
    activo_nuevo          CHAR(1),
    usuario_responsable   VARCHAR2(30),
    fecha_operacion       DATE DEFAULT SYSDATE,
    CONSTRAINT fk_hist_producto FOREIGN KEY (id_producto) REFERENCES producto(id_producto),
    CONSTRAINT ck_hist_operacion CHECK (tipo_operacion IN ('ALTA','EDICION','DESACTIVAR'))
);


-- Secuencias
-- Generadores de IDs para claves primarias de todas las tablas
CREATE SEQUENCE seq_usuario            START WITH 1 INCREMENT BY 1;
CREATE SEQUENCE seq_producto           START WITH 1 INCREMENT BY 1;
CREATE SEQUENCE seq_inventario         START WITH 1 INCREMENT BY 1;
CREATE SEQUENCE seq_movimiento         START WITH 1 INCREMENT BY 1;
CREATE SEQUENCE seq_proveedor          START WITH 1 INCREMENT BY 1;
CREATE SEQUENCE seq_compra             START WITH 1 INCREMENT BY 1;
CREATE SEQUENCE seq_historial_stock    START WITH 1 INCREMENT BY 1;
CREATE SEQUENCE seq_historial_producto START WITH 1 INCREMENT BY 1;


-- ============================================================
-- Paquetes
-- ============================================================

CREATE OR REPLACE PACKAGE pkg_productos AS

    PROCEDURE sp_insertar_producto (
        p_codigo      IN VARCHAR2,
        p_nombre      IN VARCHAR2,
        p_descripcion IN VARCHAR2,
        p_categoria   IN VARCHAR2,
        p_precio      IN NUMBER
    );

    PROCEDURE sp_obtener_producto(
        p_codigo      IN  VARCHAR2,
        p_nombre      OUT VARCHAR2,
        p_descripcion OUT VARCHAR2,
        p_categoria   OUT VARCHAR2,
        p_precio      OUT NUMBER
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
        p_codigo      IN VARCHAR2,
        p_nombre      IN VARCHAR2,
        p_descripcion IN VARCHAR2,
        p_categoria   IN VARCHAR2,
        p_precio      IN NUMBER
    );

    PROCEDURE sp_eliminar_producto(
        p_codigo IN VARCHAR2
    );

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


-- Implementacion de reglas de negocio de productos
CREATE OR REPLACE PACKAGE BODY pkg_productos AS

PROCEDURE sp_insertar_producto (
    p_codigo      IN VARCHAR2,
    p_nombre      IN VARCHAR2,
    p_descripcion IN VARCHAR2,
    p_categoria   IN VARCHAR2,
    p_precio      IN NUMBER
) IS
BEGIN
    -- Validacion REGEX
    IF NOT REGEXP_LIKE(p_codigo, '^PRD-[0-9]{3}$') THEN
        RAISE_APPLICATION_ERROR(-20001, 'Codigo invalido. Formato esperado: PRD-001');
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
        RAISE_APPLICATION_ERROR(-20003, 'Ya existe un producto con ese codigo');
    WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-20099, 'Error al insertar producto');
END sp_insertar_producto;


PROCEDURE sp_obtener_producto(
    p_codigo      IN  VARCHAR2,
    p_nombre      OUT VARCHAR2,
    p_descripcion OUT VARCHAR2,
    p_categoria   OUT VARCHAR2,
    p_precio      OUT NUMBER
) IS
BEGIN
    SELECT nombre, descripcion, categoria, precio_unitario
    INTO p_nombre, p_descripcion, p_categoria, p_precio
    FROM producto
    WHERE codigo = p_codigo;
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        p_nombre      := NULL;
        p_descripcion := NULL;
        p_categoria   := NULL;
        p_precio      := NULL;
END sp_obtener_producto;

-- Listar productos con cursor explicito
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
                OR UPPER(nombre)   LIKE '%' || UPPER(v_busqueda) || '%'
              )
        ORDER BY fecha_creacion;

    v_cod   producto.codigo%TYPE;
    v_nom   producto.nombre%TYPE;
    v_cat   producto.categoria%TYPE;
    v_pre   producto.precio_unitario%TYPE;
    v_stock NUMBER;
    v_cont  NUMBER := 0;

BEGIN
    v_busqueda := CASE WHEN TRIM(p_busqueda) IS NULL THEN NULL ELSE p_busqueda END;

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

        v_cont  := v_cont + 1;
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
    p_codigo      IN VARCHAR2,
    p_nombre      IN VARCHAR2,
    p_descripcion IN VARCHAR2,
    p_categoria   IN VARCHAR2,
    p_precio      IN NUMBER
) IS
BEGIN
    UPDATE producto
    SET nombre          = p_nombre,
        descripcion     = p_descripcion,
        categoria       = p_categoria,
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

-- Funciones
FUNCTION fn_codigo_producto_valido (
    p_codigo IN VARCHAR2
) RETURN BOOLEAN IS
BEGIN
    RETURN REGEXP_LIKE(p_codigo, '^PRD-[0-9]{3}$');
END;


FUNCTION fn_total_productos_activos RETURN NUMBER IS
    v_total NUMBER;
BEGIN
    SELECT COUNT(*) INTO v_total FROM producto WHERE activo = 'S';
    RETURN v_total;
END;


FUNCTION fn_stock_producto (
    p_codigo_producto IN VARCHAR2
) RETURN NUMBER IS
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
    WHEN NO_DATA_FOUND THEN RETURN -1;
    WHEN OTHERS        THEN RETURN -2;
END;

END pkg_productos;
/


-- Gestion de movimientos de inventario
CREATE OR REPLACE PACKAGE pkg_movimientos AS

    PROCEDURE sp_registrar_movimiento (
        p_codigo_producto IN VARCHAR2,
        p_usuario         IN VARCHAR2,
        p_tipo            IN VARCHAR2,
        p_cantidad        IN NUMBER,
        p_observacion     IN VARCHAR2,
        p_stock_minimo    IN NUMBER DEFAULT NULL
    );

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


-- Implementacion de movimientos y consultas recientes
CREATE OR REPLACE PACKAGE BODY pkg_movimientos AS

PROCEDURE sp_registrar_movimiento (
    p_codigo_producto IN VARCHAR2,
    p_usuario         IN VARCHAR2,
    p_tipo            IN VARCHAR2,
    p_cantidad        IN NUMBER,
    p_observacion     IN VARCHAR2,
    p_stock_minimo    IN NUMBER DEFAULT NULL
) IS
    v_id_producto producto.id_producto%TYPE;
    v_id_usuario  usuario.id_usuario%TYPE;
BEGIN
    DBMS_SESSION.SET_IDENTIFIER(p_usuario);

    IF p_cantidad <= 0 THEN
        RAISE_APPLICATION_ERROR(-20001, 'La cantidad debe ser mayor a cero');
    END IF;

    IF p_tipo NOT IN ('ENTRADA','SALIDA','AJUSTE') THEN
        RAISE_APPLICATION_ERROR(-20001, 'Tipo de movimiento invalido');
    END IF;

    SELECT id_producto INTO v_id_producto
    FROM producto
    WHERE codigo = p_codigo_producto AND activo = 'S';

    SELECT id_usuario INTO v_id_usuario
    FROM usuario
    WHERE username = p_usuario AND activo = 'S';

    IF p_stock_minimo IS NOT NULL THEN
        UPDATE inventario
        SET stock_minimo = p_stock_minimo
        WHERE id_producto = v_id_producto;
    END IF;

    INSERT INTO movimiento (
        id_movimiento, id_producto, id_usuario,
        tipo_movimiento, cantidad, observacion, fecha_movimiento
    ) VALUES (
        seq_movimiento.NEXTVAL,
        v_id_producto,
        v_id_usuario,
        p_tipo,
        p_cantidad,
        p_observacion,
        SYSDATE
    );

EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RAISE_APPLICATION_ERROR(-20002, 'Producto o usuario no existe');
    WHEN OTHERS THEN
        IF SQLCODE BETWEEN -20999 AND -20000 THEN RAISE; END IF;
        RAISE_APPLICATION_ERROR(-20003, 'Error al registrar movimiento');
END sp_registrar_movimiento;


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

    v_cod   producto.codigo%TYPE;
    v_tipo  movimiento.tipo_movimiento%TYPE;
    v_cant  movimiento.cantidad%TYPE;
    v_fecha movimiento.fecha_movimiento%TYPE;
    v_cont  NUMBER := 0;
BEGIN
    p_total := 0;

    OPEN c_mov;
    LOOP
        FETCH c_mov INTO v_cod, v_tipo, v_cant, v_fecha;
        EXIT WHEN c_mov%NOTFOUND OR v_cont = 5;

        v_cont  := v_cont + 1;
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

-- Gestion de proveedores, asociaciones y compras
CREATE OR REPLACE PACKAGE pkg_proveedores AS

    PROCEDURE sp_registrar_proveedor (
        p_nombre   IN VARCHAR2,
        p_telefono IN VARCHAR2,
        p_email    IN VARCHAR2
    );

    PROCEDURE sp_asociar_producto_proveedor (
        p_codigo_producto IN VARCHAR2,
        p_id_proveedor    IN NUMBER
    );

    PROCEDURE sp_registrar_compra (
        p_codigo_producto IN VARCHAR2,
        p_id_proveedor    IN NUMBER,
        p_usuario         IN VARCHAR2,
        p_cantidad        IN NUMBER,
        p_costo_unitario  IN NUMBER,
        p_observacion     IN VARCHAR2,
        p_stock_minimo    IN NUMBER DEFAULT NULL
    );

END pkg_proveedores;
/

-- Implementacion de logica de proveedores y compras
CREATE OR REPLACE PACKAGE BODY pkg_proveedores AS

PROCEDURE sp_registrar_proveedor (
    p_nombre   IN VARCHAR2,
    p_telefono IN VARCHAR2,
    p_email    IN VARCHAR2
) IS
BEGIN
    INSERT INTO proveedor (id_proveedor, nombre, telefono, email, activo)
    VALUES (seq_proveedor.NEXTVAL, TRIM(p_nombre), p_telefono, p_email, 'S');
EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
        RAISE_APPLICATION_ERROR(-20200, 'Proveedor duplicado');
END sp_registrar_proveedor;

PROCEDURE sp_asociar_producto_proveedor (
    p_codigo_producto IN VARCHAR2,
    p_id_proveedor    IN NUMBER
) IS
    v_id_producto producto.id_producto%TYPE;
    v_dummy NUMBER;
BEGIN
    SELECT id_producto INTO v_id_producto
    FROM producto
    WHERE codigo = p_codigo_producto AND activo = 'S';

    SELECT 1 INTO v_dummy
    FROM proveedor
    WHERE id_proveedor = p_id_proveedor AND activo = 'S';

    MERGE INTO producto_proveedor pp
    USING (SELECT v_id_producto AS id_producto, p_id_proveedor AS id_proveedor FROM dual) src
    ON (pp.id_producto = src.id_producto AND pp.id_proveedor = src.id_proveedor)
    WHEN MATCHED THEN
        UPDATE SET pp.activo = 'S', pp.fecha_asociacion = SYSDATE
    WHEN NOT MATCHED THEN
        INSERT (id_producto, id_proveedor, activo, fecha_asociacion)
        VALUES (src.id_producto, src.id_proveedor, 'S', SYSDATE);

EXCEPTION
    WHEN NO_DATA_FOUND THEN
        BEGIN
            SELECT 1 INTO v_dummy FROM producto
            WHERE codigo = p_codigo_producto AND activo = 'S';
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                RAISE_APPLICATION_ERROR(-20201, 'Producto no valido');
        END;
        RAISE_APPLICATION_ERROR(-20202, 'Proveedor no valido');
END sp_asociar_producto_proveedor;

PROCEDURE sp_registrar_compra (
    p_codigo_producto IN VARCHAR2,
    p_id_proveedor    IN NUMBER,
    p_usuario         IN VARCHAR2,
    p_cantidad        IN NUMBER,
    p_costo_unitario  IN NUMBER,
    p_observacion     IN VARCHAR2,
    p_stock_minimo    IN NUMBER DEFAULT NULL
) IS
    v_id_producto producto.id_producto%TYPE;
    v_id_usuario  usuario.id_usuario%TYPE;
    v_dummy NUMBER;
BEGIN
    IF p_cantidad <= 0 THEN
        RAISE_APPLICATION_ERROR(-20204, 'Cantidad invalida');
    END IF;

    IF p_costo_unitario < 0 THEN
        RAISE_APPLICATION_ERROR(-20205, 'Costo unitario invalido');
    END IF;

    SELECT id_producto INTO v_id_producto
    FROM producto WHERE codigo = p_codigo_producto AND activo = 'S';

    SELECT id_usuario INTO v_id_usuario
    FROM usuario WHERE username = p_usuario AND activo = 'S';

    SELECT 1 INTO v_dummy
    FROM proveedor WHERE id_proveedor = p_id_proveedor AND activo = 'S';

    SELECT 1 INTO v_dummy
    FROM producto_proveedor
    WHERE id_producto = v_id_producto AND id_proveedor = p_id_proveedor AND activo = 'S';

    INSERT INTO compra_proveedor (
        id_compra, id_producto, id_proveedor, id_usuario,
        cantidad, costo_unitario, observacion, fecha_compra
    ) VALUES (
        seq_compra.NEXTVAL,
        v_id_producto,
        p_id_proveedor,
        v_id_usuario,
        p_cantidad,
        p_costo_unitario,
        p_observacion,
        SYSDATE
    );

    pkg_movimientos.sp_registrar_movimiento(
        p_codigo_producto,
        p_usuario,
        'ENTRADA',
        p_cantidad,
        NVL(p_observacion, 'Compra a proveedor #' || p_id_proveedor),
        p_stock_minimo
    );

EXCEPTION
    WHEN NO_DATA_FOUND THEN
        BEGIN
            SELECT 1 INTO v_dummy FROM producto
            WHERE codigo = p_codigo_producto AND activo = 'S';
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                RAISE_APPLICATION_ERROR(-20201, 'Producto no valido');
        END;

        BEGIN
            SELECT 1 INTO v_dummy FROM proveedor
            WHERE id_proveedor = p_id_proveedor AND activo = 'S';
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                RAISE_APPLICATION_ERROR(-20202, 'Proveedor no valido');
        END;

        RAISE_APPLICATION_ERROR(-20203, 'Producto no asociado al proveedor');
    WHEN OTHERS THEN
        IF SQLCODE BETWEEN -20999 AND -20000 THEN RAISE; END IF;
        RAISE_APPLICATION_ERROR(-20299, 'Error al registrar compra');
END sp_registrar_compra;

END pkg_proveedores;
/

-- Reportes de productos por filtros dinamicos
CREATE OR REPLACE PACKAGE pkg_reportes AS

    PROCEDURE sp_buscar_productos (
        p_categoria  IN VARCHAR2,
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

-- Implementacion de reporte dinamico con SQL y binds variables
CREATE OR REPLACE PACKAGE BODY pkg_reportes AS

PROCEDURE sp_buscar_productos (
    p_categoria  IN VARCHAR2,
    p_min_precio IN NUMBER,
    p_max_precio IN NUMBER,

    p_total OUT NUMBER,
    p_cod1 OUT VARCHAR2, p_nom1 OUT VARCHAR2, p_pre1 OUT NUMBER,
    p_cod2 OUT VARCHAR2, p_nom2 OUT VARCHAR2, p_pre2 OUT NUMBER,
    p_cod3 OUT VARCHAR2, p_nom3 OUT VARCHAR2, p_pre3 OUT NUMBER,
    p_cod4 OUT VARCHAR2, p_nom4 OUT VARCHAR2, p_pre4 OUT NUMBER,
    p_cod5 OUT VARCHAR2, p_nom5 OUT VARCHAR2, p_pre5 OUT NUMBER
) IS

    TYPE ref_cursor IS REF CURSOR;
    c_ref ref_cursor;
    v_sql VARCHAR2(1000);

    v_cod producto.codigo%TYPE;
    v_nom producto.nombre%TYPE;
    v_pre producto.precio_unitario%TYPE;

    v_cont NUMBER := 0;

BEGIN
    v_sql := 'SELECT codigo, nombre, precio_unitario FROM producto WHERE activo = ''S''';

    IF p_categoria  IS NOT NULL THEN v_sql := v_sql || ' AND categoria = :cat';         END IF;
    IF p_min_precio IS NOT NULL THEN v_sql := v_sql || ' AND precio_unitario >= :minp'; END IF;
    IF p_max_precio IS NOT NULL THEN v_sql := v_sql || ' AND precio_unitario <= :maxp'; END IF;

    v_sql := v_sql || ' ORDER BY nombre';

    -- -------------------------------------------------------
    -- Abrir cursor con los bind variables correctos
    -- Se cubren las 8 combinaciones posibles de los 3 filtros
    -- -------------------------------------------------------
    IF    p_categoria IS NOT NULL AND p_min_precio IS NOT NULL AND p_max_precio IS NOT NULL THEN
        OPEN c_ref FOR v_sql USING p_categoria, p_min_precio, p_max_precio;

    ELSIF p_categoria IS NOT NULL AND p_min_precio IS NOT NULL AND p_max_precio IS NULL THEN
        OPEN c_ref FOR v_sql USING p_categoria, p_min_precio;

    ELSIF p_categoria IS NOT NULL AND p_min_precio IS NULL    AND p_max_precio IS NOT NULL THEN
        OPEN c_ref FOR v_sql USING p_categoria, p_max_precio;

    ELSIF p_categoria IS NOT NULL AND p_min_precio IS NULL    AND p_max_precio IS NULL THEN
        OPEN c_ref FOR v_sql USING p_categoria;

    ELSIF p_categoria IS NULL     AND p_min_precio IS NOT NULL AND p_max_precio IS NOT NULL THEN
        OPEN c_ref FOR v_sql USING p_min_precio, p_max_precio;

    ELSIF p_categoria IS NULL     AND p_min_precio IS NOT NULL AND p_max_precio IS NULL THEN
        OPEN c_ref FOR v_sql USING p_min_precio;

    ELSIF p_categoria IS NULL     AND p_min_precio IS NULL    AND p_max_precio IS NOT NULL THEN
        OPEN c_ref FOR v_sql USING p_max_precio;

    ELSE
        OPEN c_ref FOR v_sql;
    END IF;

    p_total := 0;

    LOOP
        FETCH c_ref INTO v_cod, v_nom, v_pre;
        EXIT WHEN c_ref%NOTFOUND OR v_cont = 5;

        v_cont  := v_cont + 1;
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
        RAISE_APPLICATION_ERROR(-20030, 'Error en busqueda dinamica de productos');
END sp_buscar_productos;

END pkg_reportes;
/


-- Reportes de productos con stock critico
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


-- Implementacion del reporte de stock minimo
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
        SELECT p.codigo, p.nombre, i.cantidad_actual, i.stock_minimo
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

        v_cont  := v_cont + 1;
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
        RAISE_APPLICATION_ERROR(-20030, 'Error al generar reporte de stock minimo');
END sp_reporte_stock_minimo;

END pkg_reportes_stock;
/


-- Autenticacion de usuarios
CREATE OR REPLACE PACKAGE pkg_login AS

    PROCEDURE sp_login (
        p_username IN VARCHAR2,
        p_password IN VARCHAR2,
        p_rol      OUT VARCHAR2
    );

END pkg_login;
/


-- Administracion de usuarios y roles
CREATE OR REPLACE PACKAGE pkg_usuarios AS

    PROCEDURE sp_registrar_usuario (
        p_username IN VARCHAR2,
        p_password IN VARCHAR2,
        p_rol      IN VARCHAR2
    );

    PROCEDURE sp_actualizar_rol (
        p_username IN VARCHAR2,
        p_rol      IN VARCHAR2
    );

    PROCEDURE sp_desactivar_usuario (
        p_username IN VARCHAR2
    );

END pkg_usuarios;
/


-- Implementacion de alta/actualizacion/baja de usuarios
CREATE OR REPLACE PACKAGE BODY pkg_usuarios AS

PROCEDURE sp_registrar_usuario (
    p_username IN VARCHAR2,
    p_password IN VARCHAR2,
    p_rol      IN VARCHAR2
) IS
BEGIN
    IF p_username IS NULL OR TRIM(p_username) IS NULL THEN
        RAISE_APPLICATION_ERROR(-20304, 'Usuario requerido');
    END IF;

    IF p_password IS NULL OR TRIM(p_password) IS NULL THEN
        RAISE_APPLICATION_ERROR(-20305, 'Contrasena requerida');
    END IF;

    IF p_rol NOT IN ('ADMIN','OPERADOR') THEN
        RAISE_APPLICATION_ERROR(-20301, 'Rol invalido');
    END IF;

    INSERT INTO usuario (id_usuario, username, password, rol, activo, fecha_creacion)
    VALUES (
        seq_usuario.NEXTVAL,
        TRIM(p_username),
        RAWTOHEX(DBMS_CRYPTO.HASH(UTL_RAW.CAST_TO_RAW(TRIM(p_password)), DBMS_CRYPTO.HASH_SH1)),
        p_rol,
        'S',
        SYSDATE
    );
EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
        RAISE_APPLICATION_ERROR(-20302, 'Usuario duplicado');
END sp_registrar_usuario;

PROCEDURE sp_actualizar_rol (
    p_username IN VARCHAR2,
    p_rol      IN VARCHAR2
) IS
BEGIN
    IF p_rol NOT IN ('ADMIN','OPERADOR') THEN
        RAISE_APPLICATION_ERROR(-20301, 'Rol invalido');
    END IF;

    UPDATE usuario SET rol = p_rol
    WHERE username = p_username AND activo = 'S';

    IF SQL%ROWCOUNT = 0 THEN
        RAISE_APPLICATION_ERROR(-20303, 'Usuario no activo o no existe');
    END IF;
END sp_actualizar_rol;

PROCEDURE sp_desactivar_usuario (
    p_username IN VARCHAR2
) IS
BEGIN
    UPDATE usuario SET activo = 'N'
    WHERE username = p_username AND activo = 'S';

    IF SQL%ROWCOUNT = 0 THEN
        RAISE_APPLICATION_ERROR(-20303, 'Usuario no activo o no existe');
    END IF;
END sp_desactivar_usuario;

END pkg_usuarios;
/


-- Implementacion del proceso de login
CREATE OR REPLACE PACKAGE BODY pkg_login AS

PROCEDURE sp_login (
    p_username IN VARCHAR2,
    p_password IN VARCHAR2,
    p_rol      OUT VARCHAR2
) IS
    v_count NUMBER;
BEGIN
    IF p_username IS NULL OR TRIM(p_username) IS NULL THEN
        RAISE_APPLICATION_ERROR(-20001, 'Usuario requerido');
    END IF;

    IF p_password IS NULL OR TRIM(p_password) IS NULL THEN
        RAISE_APPLICATION_ERROR(-20001, 'Contrasena requerida');
    END IF;

    SELECT COUNT(*)
    INTO v_count
    FROM usuario
    WHERE username = TRIM(p_username)
      AND password = RAWTOHEX(DBMS_CRYPTO.HASH(UTL_RAW.CAST_TO_RAW(TRIM(p_password)), DBMS_CRYPTO.HASH_SH1))
      AND activo = 'S';

    IF v_count = 0 THEN
        RAISE_APPLICATION_ERROR(-20001, 'Usuario o contrasena incorrectos');
    END IF;

    SELECT rol INTO p_rol
    FROM usuario
    WHERE username = TRIM(p_username)
      AND password = RAWTOHEX(DBMS_CRYPTO.HASH(UTL_RAW.CAST_TO_RAW(TRIM(p_password)), DBMS_CRYPTO.HASH_SH1))
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


-- ============================================================
-- Triggers
-- ============================================================
-- Automatizaciones de integridad y auditoria a nivel de BD.

-- Crear registro de inventario automaticamente al insertar un producto
CREATE OR REPLACE TRIGGER trg_crear_inventario
AFTER INSERT ON producto
FOR EACH ROW
BEGIN
    INSERT INTO inventario (
        id_inventario, id_producto, cantidad_actual, stock_minimo, fecha_actualizacion
    ) VALUES (
        seq_inventario.NEXTVAL, :NEW.id_producto, 0, 0, SYSDATE
    );
EXCEPTION
    WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-20030, 'Error al crear inventario automatico para el producto');
END;
/

-- Actualizar stock al insertar un movimiento
CREATE OR REPLACE TRIGGER trg_aplicar_movimiento_stock
BEFORE INSERT ON movimiento
FOR EACH ROW
DECLARE
    v_stock_actual inventario.cantidad_actual%TYPE;
BEGIN
    SELECT cantidad_actual
    INTO v_stock_actual
    FROM inventario
    WHERE id_producto = :NEW.id_producto
    FOR UPDATE;

    IF :NEW.tipo_movimiento = 'SALIDA' AND v_stock_actual < :NEW.cantidad THEN
        RAISE_APPLICATION_ERROR(-20011, 'Stock insuficiente');
    END IF;

    IF :NEW.tipo_movimiento = 'ENTRADA' THEN
        UPDATE inventario
        SET cantidad_actual = cantidad_actual + :NEW.cantidad, fecha_actualizacion = SYSDATE
        WHERE id_producto = :NEW.id_producto;
    ELSIF :NEW.tipo_movimiento = 'SALIDA' THEN
        UPDATE inventario
        SET cantidad_actual = cantidad_actual - :NEW.cantidad, fecha_actualizacion = SYSDATE
        WHERE id_producto = :NEW.id_producto;
    ELSIF :NEW.tipo_movimiento = 'AJUSTE' THEN
        UPDATE inventario
        SET cantidad_actual = :NEW.cantidad, fecha_actualizacion = SYSDATE
        WHERE id_producto = :NEW.id_producto;
    ELSE
        RAISE_APPLICATION_ERROR(-20012, 'Tipo de movimiento invalido');
    END IF;
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RAISE_APPLICATION_ERROR(-20013, 'No existe inventario para el producto');
END;
/

-- Registrar historial cuando cambia stock o stock minimo
CREATE OR REPLACE TRIGGER trg_historial_stock
AFTER UPDATE OF cantidad_actual, stock_minimo ON inventario
FOR EACH ROW
DECLARE
    v_usuario VARCHAR2(30);
    v_origen  VARCHAR2(40);
BEGIN
    v_usuario := SYS_CONTEXT('USERENV', 'CLIENT_IDENTIFIER');
    IF v_usuario IS NULL THEN v_usuario := USER; END IF;

    IF NVL(:NEW.cantidad_actual, -999999) != NVL(:OLD.cantidad_actual, -999999) THEN
        v_origen := 'MOVIMIENTO';
    ELSIF NVL(:NEW.stock_minimo, -999999) != NVL(:OLD.stock_minimo, -999999) THEN
        v_origen := 'STOCK_MINIMO';
    ELSE
        v_origen := 'INVENTARIO';
    END IF;

    INSERT INTO historial_stock (
        id_historial, id_inventario,
        cantidad_anterior, cantidad_nueva,
        stock_minimo_anterior, stock_minimo_nuevo,
        usuario_responsable, fecha_cambio, origen
    ) VALUES (
        seq_historial_stock.NEXTVAL, :NEW.id_inventario,
        :OLD.cantidad_actual, :NEW.cantidad_actual,
        :OLD.stock_minimo,    :NEW.stock_minimo,
        v_usuario, SYSDATE, v_origen
    );
END;
/

-- Registrar historial de cambios en producto
CREATE OR REPLACE TRIGGER trg_historial_producto
AFTER INSERT OR UPDATE ON producto
FOR EACH ROW
DECLARE
    v_usuario        VARCHAR2(30);
    v_operacion      VARCHAR2(20);
    -- Variables para los valores anteriores (NULL en ALTA, valor real en EDICION/DESACTIVAR)
    v_nombre_ant     producto.nombre%TYPE;
    v_desc_ant       producto.descripcion%TYPE;
    v_cat_ant        producto.categoria%TYPE;
    v_precio_ant     producto.precio_unitario%TYPE;
    v_activo_ant     CHAR(1);
BEGIN
    v_usuario := SYS_CONTEXT('USERENV', 'CLIENT_IDENTIFIER');
    IF v_usuario IS NULL THEN v_usuario := USER; END IF;

    IF INSERTING THEN
        -- Alta: no hay valores anteriores
        v_operacion  := 'ALTA';
        v_nombre_ant := NULL;
        v_desc_ant   := NULL;
        v_cat_ant    := NULL;
        v_precio_ant := NULL;
        v_activo_ant := NULL;
    ELSE
        -- Update: capturar valores anteriores en variables PL/SQL
        -- (INSERTING no puede usarse dentro de expresiones SQL como CASE...WHEN)
        v_nombre_ant := :OLD.nombre;
        v_desc_ant   := :OLD.descripcion;
        v_cat_ant    := :OLD.categoria;
        v_precio_ant := :OLD.precio_unitario;
        v_activo_ant := :OLD.activo;

        IF NVL(:OLD.activo, 'S') = 'S' AND NVL(:NEW.activo, 'S') = 'N' THEN
            v_operacion := 'DESACTIVAR';
        ELSE
            v_operacion := 'EDICION';
        END IF;
    END IF;

    INSERT INTO historial_producto (
        id_historial_producto, id_producto, codigo, tipo_operacion,
        nombre_anterior,       nombre_nuevo,
        descripcion_anterior,  descripcion_nueva,
        categoria_anterior,    categoria_nueva,
        precio_anterior,       precio_nuevo,
        activo_anterior,       activo_nuevo,
        usuario_responsable,   fecha_operacion
    ) VALUES (
        seq_historial_producto.NEXTVAL,
        :NEW.id_producto,
        :NEW.codigo,
        v_operacion,
        v_nombre_ant,  :NEW.nombre,
        v_desc_ant,    :NEW.descripcion,
        v_cat_ant,     :NEW.categoria,
        v_precio_ant,  :NEW.precio_unitario,
        v_activo_ant,  :NEW.activo,
        v_usuario,
        SYSDATE
    );
END;
/


-- ============================================================
-- PARTE 3: Datos de prueba
-- ============================================================


-- Limpiar datos previos (por si se re-ejecuta esta seccion)
DELETE FROM historial_producto;
DELETE FROM historial_stock;
DELETE FROM compra_proveedor;
DELETE FROM movimiento;
DELETE FROM producto_proveedor;
DELETE FROM inventario;
DELETE FROM producto;
DELETE FROM proveedor;
DELETE FROM usuario;

COMMIT;


-- Crear usuarios

BEGIN
    INSERT INTO usuario
    VALUES (seq_usuario.NEXTVAL, 'admin',
            RAWTOHEX(DBMS_CRYPTO.HASH(UTL_RAW.CAST_TO_RAW('admin123'), DBMS_CRYPTO.HASH_SH1)),
            'ADMIN', 'S', SYSDATE);

    INSERT INTO usuario
    VALUES (seq_usuario.NEXTVAL, 'operador',
            RAWTOHEX(DBMS_CRYPTO.HASH(UTL_RAW.CAST_TO_RAW('op123'), DBMS_CRYPTO.HASH_SH1)),
            'OPERADOR', 'S', SYSDATE);

    COMMIT;
END;
/


-- Insertar productos (el trigger trg_crear_inventario crea el inventario automaticamente)
BEGIN
    pkg_productos.sp_insertar_producto('PRD-001', 'Mouse USB',        'Mouse Optico',  'Perifericos', 5500);
    pkg_productos.sp_insertar_producto('PRD-002', 'Teclado Mecanico', 'Switch azul',   'Perifericos', 22000);
    pkg_productos.sp_insertar_producto('PRD-003', 'Monitor 24',       'Full HD',       'Pantallas',   95000);
END;
/

-- Registrar proveedores
BEGIN
    pkg_proveedores.sp_registrar_proveedor('Distribuidora Norte', '2200-1100', 'norte@proveedor.com');
    pkg_proveedores.sp_registrar_proveedor('Importadora Delta',   '2200-2200', 'delta@proveedor.com');
END;
/

-- Asociar productos a proveedores
-- En PL/SQL no se puede pasar un SELECT inline como argumento; se usan variables.
DECLARE
    v_id_norte NUMBER;
    v_id_delta  NUMBER;
BEGIN
    SELECT id_proveedor INTO v_id_norte FROM proveedor WHERE nombre = 'Distribuidora Norte';
    SELECT id_proveedor INTO v_id_delta  FROM proveedor WHERE nombre = 'Importadora Delta';

    pkg_proveedores.sp_asociar_producto_proveedor('PRD-001', v_id_norte);
    pkg_proveedores.sp_asociar_producto_proveedor('PRD-002', v_id_norte);
    pkg_proveedores.sp_asociar_producto_proveedor('PRD-003', v_id_delta);
END;
/

-- Registrar compra a proveedor (genera ENTRADA en movimiento automaticamente)
DECLARE
    v_id_norte NUMBER;
BEGIN
    SELECT id_proveedor INTO v_id_norte FROM proveedor WHERE nombre = 'Distribuidora Norte';

    pkg_proveedores.sp_registrar_compra(
        'PRD-001',
        v_id_norte,
        'admin',
        30,
        4800,
        'Compra proveedor principal',
        10  -- stock minimo
    );
END;
/


-- Verificar inventario creado por trigger
SELECT p.codigo, i.cantidad_actual, i.stock_minimo
FROM inventario i
JOIN producto p ON p.id_producto = i.id_producto;

-- Registrar movimientos adicionales
BEGIN
    pkg_movimientos.sp_registrar_movimiento('PRD-001', 'admin', 'ENTRADA', 50, 'Compra inicial');
    pkg_movimientos.sp_registrar_movimiento('PRD-002', 'admin', 'ENTRADA', 20, 'Compra proveedor');
END;
/

-- Movimiento valido: salida with stock suficiente
BEGIN
    pkg_movimientos.sp_registrar_movimiento('PRD-001', 'operador', 'SALIDA', 10, 'Venta');
END;
/

-- Movimiento invalido: salida con stock insuficiente (debe lanzar error ORA-20011)
BEGIN
    pkg_movimientos.sp_registrar_movimiento('PRD-002', 'operador', 'SALIDA', 999, 'Prueba error');
END;
/

-- Ajustar stock minimo manualmente
UPDATE inventario
SET stock_minimo = 15
WHERE id_producto = (SELECT id_producto FROM producto WHERE codigo = 'PRD-001');

COMMIT;


-- Reporte de productos con stock critico (cantidad_actual <= stock_minimo)
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
        c1,n1,q1,m1, c2,n2,q2,m2, c3,n3,q3,m3,
        c4,n4,q4,m4, c5,n5,q5,m5
    );

    DBMS_OUTPUT.PUT_LINE('Productos criticos: ' || v_total);
    IF v_total >= 1 THEN DBMS_OUTPUT.PUT_LINE(c1 || ' - ' || n1 || ' (' || q1 || '/' || m1 || ')'); END IF;
END;
/


-- Probar login correcto
DECLARE
    v_rol VARCHAR2(20);
BEGIN
    pkg_login.sp_login('admin','admin123',v_rol);
    DBMS_OUTPUT.PUT_LINE('Login OK. Rol: ' || v_rol);
END;
/

-- Probar login invalido (debe lanzar error ORA-20001)
DECLARE
    v_rol VARCHAR2(20);
BEGIN
    pkg_login.sp_login('admin','1234',v_rol);
    DBMS_OUTPUT.PUT_LINE('Login OK. Rol: ' || v_rol);
END;
/

-- ============================================================
-- Probar listado de productos con busqueda
-- CORREGIDO: se agregan las variables p_stock1..p_stock5 que faltaban
-- ============================================================
DECLARE
    v_total NUMBER;
    c1 VARCHAR2(20); n1 VARCHAR2(100); cat1 VARCHAR2(50); p1 NUMBER; s1 NUMBER;
    c2 VARCHAR2(20); n2 VARCHAR2(100); cat2 VARCHAR2(50); p2 NUMBER; s2 NUMBER;
    c3 VARCHAR2(20); n3 VARCHAR2(100); cat3 VARCHAR2(50); p3 NUMBER; s3 NUMBER;
    c4 VARCHAR2(20); n4 VARCHAR2(100); cat4 VARCHAR2(50); p4 NUMBER; s4 NUMBER;
    c5 VARCHAR2(20); n5 VARCHAR2(100); cat5 VARCHAR2(50); p5 NUMBER; s5 NUMBER;
BEGIN
    pkg_productos.sp_listar_productos(
        p_busqueda => 'TECLADO',
        p_total    => v_total,
        p_cod1 => c1, p_nom1 => n1, p_cat1 => cat1, p_pre1 => p1, p_stock1 => s1,
        p_cod2 => c2, p_nom2 => n2, p_cat2 => cat2, p_pre2 => p2, p_stock2 => s2,
        p_cod3 => c3, p_nom3 => n3, p_cat3 => cat3, p_pre3 => p3, p_stock3 => s3,
        p_cod4 => c4, p_nom4 => n4, p_cat4 => cat4, p_pre4 => p4, p_stock4 => s4,
        p_cod5 => c5, p_nom5 => n5, p_cat5 => cat5, p_pre5 => p5, p_stock5 => s5
    );

    DBMS_OUTPUT.PUT_LINE('Total productos encontrados: ' || v_total);
    IF v_total >= 1 THEN DBMS_OUTPUT.PUT_LINE(c1||' - '||n1||' - '||cat1||' - $'||p1||' (stock: '||s1||')'); END IF;
    IF v_total >= 2 THEN DBMS_OUTPUT.PUT_LINE(c2||' - '||n2||' - '||cat2||' - $'||p2||' (stock: '||s2||')'); END IF;
    IF v_total >= 3 THEN DBMS_OUTPUT.PUT_LINE(c3||' - '||n3||' - '||cat3||' - $'||p3||' (stock: '||s3||')'); END IF;
    IF v_total >= 4 THEN DBMS_OUTPUT.PUT_LINE(c4||' - '||n4||' - '||cat4||' - $'||p4||' (stock: '||s4||')'); END IF;
    IF v_total >= 5 THEN DBMS_OUTPUT.PUT_LINE(c5||' - '||n5||' - '||cat5||' - $'||p5||' (stock: '||s5||')'); END IF;
END;
/


-- Probar funcion de validacion de codigo
BEGIN
    IF pkg_productos.fn_codigo_producto_valido('PRD-001') THEN
        DBMS_OUTPUT.PUT_LINE('Codigo OK');
    ELSE
        DBMS_OUTPUT.PUT_LINE('Codigo invalido');
    END IF;
END;
/

-- Probar funcion de total de productos activos
DECLARE v_total NUMBER;
BEGIN
    v_total := pkg_productos.fn_total_productos_activos;
    DBMS_OUTPUT.PUT_LINE('Productos activos: ' || v_total);
END;
/

-- Probar funcion de stock por producto
DECLARE v_stock NUMBER;
BEGIN
    v_stock := pkg_productos.fn_stock_producto('PRD-001');
    IF v_stock >= 0 THEN
        DBMS_OUTPUT.PUT_LINE('Stock actual PRD-001: ' || v_stock);
    ELSE
        DBMS_OUTPUT.PUT_LINE('Producto no encontrado o sin inventario');
    END IF;
END;
/


-- Consultas de verificacion
-- Comprobaciones rapidas para inspeccionar metadata y datos creados
SELECT argument_name, data_type, in_out, position
FROM user_arguments
WHERE object_name = 'SP_LISTAR_MOVIMIENTOS'
ORDER BY position;

SELECT id_usuario FROM usuario WHERE username = 'admin';
