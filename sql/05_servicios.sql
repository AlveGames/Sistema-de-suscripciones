/* =====================================================================
   PLATAFORMA DE SERVICIOS POR SUSCRIPCIÓN - Grupo 2, Base de Datos (A1)
   servicios.sql : SQL de los módulos Servicio y Modalidad
   Responsable: Castañeda

   Extraído de sql/01_estructura.sql, 03_datos.sql y 04_consultas.sql.
   NO reemplaza a esos scripts: las secciones 1 y 2 son solo para el informe
   (las tablas ya existen en la base). Las secciones 3 y 4 sí se pueden
   ejecutar en SSMS sobre PlataformaSuscripciones.
   ===================================================================== */

USE PlataformaSuscripciones;
GO

/* ---------------------------------------------------------------------
   1. ESTRUCTURA (solo referencia, ya creada por 01_estructura.sql)
   ---------------------------------------------------------------------
CREATE TABLE servicio (
    id_servicio         INT IDENTITY(1,1) NOT NULL,
    id_categoria        INT               NOT NULL,
    nombre              NVARCHAR(100)     NOT NULL,
    descripcion         NVARCHAR(300)     NULL,
    estado              NVARCHAR(10)      NOT NULL CONSTRAINT DF_servicio_estado DEFAULT (N'Activo'),
    CONSTRAINT PK_servicio           PRIMARY KEY (id_servicio),
    CONSTRAINT FK_servicio_categoria FOREIGN KEY (id_categoria) REFERENCES categoria (id_categoria),
    CONSTRAINT CK_servicio_estado    CHECK (estado IN (N'Activo', N'Inactivo'))
);

CREATE TABLE modalidad (
    id_modalidad        INT IDENTITY(1,1) NOT NULL,
    id_servicio         INT               NOT NULL,
    nombre_plan         NVARCHAR(60)      NOT NULL,
    duracion_servicio   INT               NOT NULL,   -- duración en meses
    precio_base         DECIMAL(10,2)     NOT NULL,
    CONSTRAINT PK_modalidad                PRIMARY KEY (id_modalidad),
    CONSTRAINT FK_modalidad_servicio       FOREIGN KEY (id_servicio) REFERENCES servicio (id_servicio),
    CONSTRAINT UQ_modalidad_servicio_plan  UNIQUE (id_servicio, nombre_plan),
    CONSTRAINT CK_modalidad_duracion       CHECK (duracion_servicio > 0),
    CONSTRAINT CK_modalidad_precio         CHECK (precio_base >= 0)
);
   --------------------------------------------------------------------- */

/* ---------------------------------------------------------------------
   2. DATOS DE PRUEBA (solo referencia, ya cargados por 03_datos.sql)
   ---------------------------------------------------------------------
INSERT INTO servicio (id_categoria, nombre, descripcion, estado) VALUES
    (1, N'NubeDrive',   N'Almacenamiento de archivos en la nube',            N'Activo'),   -- 1
    (1, N'NubeBackup',  N'Copias de seguridad automáticas',                  N'Activo'),   -- 2
    (2, N'CineStream',  N'Películas y series por streaming',                 N'Activo'),   -- 3
    (2, N'MúsicaYa',    N'Música por streaming',                             N'Activo'),   -- 4
    (3, N'AulaVirtual', N'Cursos en línea de tecnología',                    N'Activo'),   -- 5
    (4, N'OfiPro',      N'Herramientas de oficina en línea',                 N'Activo'),   -- 6
    (3, N'IdiomasPlus', N'Cursos de idiomas (fuera de venta por ahora)',     N'Inactivo'); -- 7

INSERT INTO modalidad (id_servicio, nombre_plan, duracion_servicio, precio_base) VALUES
    (1, N'Básico mensual',      1,   2.99),   -- 1
    (1, N'Estándar anual',     12,  60.00),   -- 2
    (1, N'Premium anual',      12, 120.00),   -- 3
    (2, N'Mensual',             1,   4.50),   -- 4
    (2, N'Anual',              12,  45.00),   -- 5
    (3, N'Básico mensual',      1,   5.99),   -- 6
    (3, N'Estándar mensual',    1,   8.99),   -- 7
    (3, N'Premium mensual',     1,  12.99),   -- 8
    (4, N'Individual mensual',  1,   4.99),   -- 9
    (4, N'Familiar mensual',    1,   7.99),   -- 10
    (5, N'Mensual',             1,  15.00),   -- 11
    (5, N'Semestral',           6,  75.00),   -- 12
    (6, N'Personal anual',     12,  69.99),   -- 13
    (6, N'Empresarial anual',  12, 249.99),   -- 14
    (7, N'Mensual',             1,   9.99);   -- 15
   --------------------------------------------------------------------- */

/* ---------------------------------------------------------------------
   3. CONSULTAS DE VERIFICACIÓN (se pueden ejecutar)
   --------------------------------------------------------------------- */

-- 3.1 Servicios con su categoría
SELECT s.id_servicio, s.nombre, c.nombre AS categoria, s.estado
FROM servicio s
JOIN categoria c ON c.id_categoria = s.id_categoria
ORDER BY s.nombre;
GO

-- 3.2 Modalidades por servicio
SELECT s.nombre AS servicio, m.nombre_plan, m.duracion_servicio, m.precio_base
FROM modalidad m
JOIN servicio s ON s.id_servicio = m.id_servicio
ORDER BY s.nombre, m.nombre_plan;
GO

-- 3.3 Suscripciones activas por categoría y servicio (Consulta 3 del equipo)
--     LEFT JOIN para que aparezcan los servicios sin suscripciones (cuentan 0).
SELECT c.nombre                         AS [Categoría],
       sv.nombre                        AS [Servicio],
       sv.estado                        AS [Estado del servicio],
       COUNT(DISTINCT m.id_modalidad)   AS [Planes],
       COUNT(s.id_suscripcion)          AS [Suscripciones activas]
FROM categoria c
JOIN servicio sv        ON sv.id_categoria = c.id_categoria
LEFT JOIN modalidad m   ON m.id_servicio   = sv.id_servicio
LEFT JOIN suscripcion s ON s.id_modalidad  = m.id_modalidad
                       AND s.id_estado_suscripcion = 1      -- 1 = Activa
GROUP BY c.nombre, sv.nombre, sv.estado
ORDER BY c.nombre, sv.nombre;
GO

/* ---------------------------------------------------------------------
   4. PRUEBAS DE INTEGRIDAD (cada una debe fallar)
   Van dentro de BEGIN TRAN ... ROLLBACK para no dejar datos en la base.
   Ejecutar de una en una y tomar la captura del error.
   --------------------------------------------------------------------- */

-- 4.1 Plan duplicado en el mismo servicio -> viola UQ_modalidad_servicio_plan
BEGIN TRAN;
INSERT INTO modalidad (id_servicio, nombre_plan, duracion_servicio, precio_base)
VALUES (1, N'Básico mensual', 1, 2.99);
ROLLBACK;
GO

-- 4.2 Duración cero -> viola CK_modalidad_duracion
BEGIN TRAN;
INSERT INTO modalidad (id_servicio, nombre_plan, duracion_servicio, precio_base)
VALUES (1, N'Plan de prueba', 0, 10.00);
ROLLBACK;
GO

-- 4.3 Precio negativo -> viola CK_modalidad_precio
BEGIN TRAN;
INSERT INTO modalidad (id_servicio, nombre_plan, duracion_servicio, precio_base)
VALUES (1, N'Plan de prueba', 1, -5.00);
ROLLBACK;
GO

-- 4.4 Estado inválido -> viola CK_servicio_estado
BEGIN TRAN;
INSERT INTO servicio (id_categoria, nombre, estado)
VALUES (1, N'Servicio de prueba', N'Pausado');
ROLLBACK;
GO

-- 4.5 Eliminar un servicio que tiene modalidades -> viola FK_modalidad_servicio
BEGIN TRAN;
DELETE FROM servicio WHERE id_servicio = 1;
ROLLBACK;
GO

-- 4.6 Eliminar una modalidad usada por suscripciones/operaciones -> viola una FK
BEGIN TRAN;
DELETE FROM modalidad WHERE id_modalidad = 2;
ROLLBACK;
GO