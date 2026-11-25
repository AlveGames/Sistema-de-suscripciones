/* =====================================================================
   PLATAFORMA DE SERVICIOS POR SUSCRIPCIÓN  -  Grupo 2, Base de Datos (A1)
   03_datos.sql : datos de prueba

   Los catálogos, clientes, servicios y modalidades se insertan directo.
   Las suscripciones, operaciones y pagos se cargan llamando a los
   PROCEDIMIENTOS, con fechas pasadas, para que el historial cumpla
   todas las reglas del modelo. Los datos son inventados.
   Fecha de referencia ("hoy" para los datos): 2026-11-24.
   ===================================================================== */

USE PlataformaSuscripciones;
GO
SET NOCOUNT ON;
GO

/* ---------------------------------------------------------------------
   CATÁLOGOS
   (estado_suscripcion y tipo_operacion ya se cargaron en 01_estructura.sql)
   --------------------------------------------------------------------- */

INSERT INTO categoria (nombre) VALUES
    (N'Almacenamiento en la nube'),   -- 1
    (N'Entretenimiento'),             -- 2
    (N'Educación en línea'),          -- 3
    (N'Productividad');               -- 4

INSERT INTO tipo_pago (nombre_tipo_metodo) VALUES
    (N'Tarjeta de crédito'),          -- 1
    (N'Tarjeta de débito'),           -- 2
    (N'Transferencia bancaria'),      -- 3
    (N'PayPal');                      -- 4

INSERT INTO tipo_metrica (nombre, unidad) VALUES
    (N'Almacenamiento usado',   N'GB'),          -- 1
    (N'Horas de reproducción',  N'horas'),       -- 2
    (N'Lecciones completadas',  N'lecciones'),   -- 3
    (N'Documentos creados',     N'documentos');  -- 4

/* ---------------------------------------------------------------------
   SERVICIOS Y MODALIDADES
   --------------------------------------------------------------------- */

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

/* ---------------------------------------------------------------------
   CLIENTES
   --------------------------------------------------------------------- */

INSERT INTO cliente (nombre, documento, correo, telefono, fecha_registro, cliente_activo, tipo_cliente) VALUES
    (N'Luis Alberto Pérez Mora',        '0912345678',    N'luis.perez@ejemplo.com',       '0991234567', '2026-01-08', 1, N'Persona'),       -- 1
    (N'María Fernanda León Vera',       '0923456789',    N'mfleon@ejemplo.com',           '0982345678', '2026-01-15', 1, N'Persona'),       -- 2
    (N'Carlos Andrés Mendoza Ruiz',     '0934567890',    N'cmendoza@ejemplo.com',         '0973456789', '2026-02-02', 1, N'Persona'),       -- 3
    (N'Ana Lucía Torres Salazar',       '0945678901',    N'ana.torres@ejemplo.com',       '0964567890', '2026-02-20', 1, N'Persona'),       -- 4
    (N'Jorge Iván Castro Paredes',      '0956789012',    N'jcastro@ejemplo.com',          '0955678901', '2026-03-05', 1, N'Persona'),       -- 5
    (N'Gabriela Estefanía Ríos Zambrano','0967890123',   N'gabriela.rios@ejemplo.com',    '0946789012', '2026-04-11', 1, N'Persona'),       -- 6
    (N'Distribuidora El Ángel S.A.',    '0990123456001', N'compras@elangel-ejemplo.com',  '042345678',  '2026-01-20', 1, N'Organización'),  -- 7
    (N'Unidad Educativa Nuevo Horizonte','0991234567001',N'sistemas@nuevohorizonte-ejemplo.com', '042876543', '2026-03-01', 1, N'Organización'), -- 8
    (N'Kevin Andrés Cedeño Bravo',      '0978901234',    N'kevin.cedeno@ejemplo.com',     '0937890123', '2026-05-18', 1, N'Persona'),       -- 9
    (N'Diana Carolina Mora Reyes',      '0989012345',    N'diana.mora@ejemplo.com',       '0928901234', '2026-06-02', 1, N'Persona');       -- 10
GO

/* ---------------------------------------------------------------------
   Procedimiento TEMPORAL de apoyo: renueva una suscripción periodo tras
   periodo hasta que su fecha_fin pase de @hasta. Solo existe mientras
   corre este script (por el #).
   --------------------------------------------------------------------- */
CREATE PROCEDURE #renovar_hasta
    @id_suscripcion INT,
    @id_tipo_pago   INT,
    @hasta          DATE
AS
BEGIN
    DECLARE @fin DATE;
    WHILE 1 = 1
    BEGIN
        -- Nombres completos porque un procedimiento temporal vive en tempdb.
        SELECT @fin = fecha_fin FROM PlataformaSuscripciones.dbo.suscripcion WHERE id_suscripcion = @id_suscripcion;
        IF @fin > @hasta BREAK;
        EXEC PlataformaSuscripciones.dbo.usp_renovar_suscripcion
             @id_suscripcion = @id_suscripcion, @id_tipo_pago = @id_tipo_pago, @fecha = @fin;
    END
END
GO

/* ---------------------------------------------------------------------
   HISTORIALES (todo pasa por los procedimientos)
   --------------------------------------------------------------------- */
DECLARE @s INT;
DECLARE @hoy DATE = '2026-11-24';

-- Cliente 1, Luis: la historia del ejemplo del CP1.
-- Contrata Estándar anual, sube a Premium, suspende y reactiva.
EXEC usp_contratar_suscripcion @id_cliente = 1, @id_modalidad = 2, @id_tipo_pago = 1, @fecha = '2026-01-10', @id_suscripcion = @s OUTPUT;
EXEC usp_modificar_suscripcion @id_suscripcion = @s, @id_modalidad_nueva = 3, @id_tipo_pago = 1, @fecha = '2026-07-15', @observacion = N'Necesita más espacio';
EXEC usp_suspender_suscripcion @id_suscripcion = @s, @fecha = '2026-09-20', @observacion = N'Viaje fuera del país';
EXEC usp_reactivar_suscripcion @id_suscripcion = @s, @fecha = '2026-10-05';

-- Cliente 2, María: CineStream mensual, renueva cada mes y en junio sube a Premium.
EXEC usp_contratar_suscripcion @id_cliente = 2, @id_modalidad = 7, @id_tipo_pago = 2, @fecha = '2026-01-15', @id_suscripcion = @s OUTPUT;
EXEC #renovar_hasta @s, 2, '2026-06-14';
EXEC usp_modificar_suscripcion @id_suscripcion = @s, @id_modalidad_nueva = 8, @id_tipo_pago = 2, @fecha = '2026-06-15', @observacion = N'Quiere calidad 4K';
EXEC #renovar_hasta @s, 2, @hoy;
-- María también tiene MúsicaYa individual.
EXEC usp_contratar_suscripcion @id_cliente = 2, @id_modalidad = 9, @id_tipo_pago = 2, @fecha = '2026-02-01', @id_suscripcion = @s OUTPUT;
EXEC #renovar_hasta @s, 2, @hoy;

-- Cliente 3, Carlos: AulaVirtual semestral (renueva) y NubeBackup mensual (cancela en junio).
EXEC usp_contratar_suscripcion @id_cliente = 3, @id_modalidad = 12, @id_tipo_pago = 3, @fecha = '2026-02-02', @id_suscripcion = @s OUTPUT;
EXEC usp_renovar_suscripcion @id_suscripcion = @s, @id_tipo_pago = 3, @fecha = '2026-08-02';
EXEC usp_contratar_suscripcion @id_cliente = 3, @id_modalidad = 4, @id_tipo_pago = 3, @fecha = '2026-02-10', @id_suscripcion = @s OUTPUT;
EXEC #renovar_hasta @s, 3, '2026-06-09';
EXEC usp_cancelar_suscripcion @id_suscripcion = @s, @fecha = '2026-06-20', @observacion = N'Ya no necesita el respaldo';

-- Cliente 4, Ana: CineStream básico, cancela en mayo y vuelve a contratar en agosto.
-- Entre medio sube el precio del plan: el historial conserva el precio de cada momento.
EXEC usp_contratar_suscripcion @id_cliente = 4, @id_modalidad = 6, @id_tipo_pago = 1, @fecha = '2026-02-20', @id_suscripcion = @s OUTPUT;
EXEC #renovar_hasta @s, 1, '2026-05-19';
EXEC usp_cancelar_suscripcion @id_suscripcion = @s, @fecha = '2026-05-25', @observacion = N'Se cambia a otra plataforma';
UPDATE modalidad SET precio_base = 6.49 WHERE id_modalidad = 6;   -- subida de precio en julio
EXEC usp_contratar_suscripcion @id_cliente = 4, @id_modalidad = 6, @id_tipo_pago = 1, @fecha = '2026-08-01', @id_suscripcion = @s OUTPUT,
     @observacion = N'Vuelve después de cancelar';
EXEC #renovar_hasta @s, 1, @hoy;

-- Cliente 5, Jorge: OfiPro personal anual y NubeDrive básico que pasa a Estándar anual.
EXEC usp_contratar_suscripcion @id_cliente = 5, @id_modalidad = 13, @id_tipo_pago = 4, @fecha = '2026-03-05', @id_suscripcion = @s OUTPUT;
EXEC usp_contratar_suscripcion @id_cliente = 5, @id_modalidad = 1, @id_tipo_pago = 4, @fecha = '2026-03-10', @id_suscripcion = @s OUTPUT;
EXEC #renovar_hasta @s, 4, '2026-05-09';
EXEC usp_modificar_suscripcion @id_suscripcion = @s, @id_modalidad_nueva = 2, @id_tipo_pago = 4, @fecha = '2026-05-10', @observacion = N'Le conviene el plan anual';

-- Cliente 6, Gabriela: MúsicaYa familiar, renueva y en noviembre se suspende.
EXEC usp_contratar_suscripcion @id_cliente = 6, @id_modalidad = 10, @id_tipo_pago = 2, @fecha = '2026-04-11', @id_suscripcion = @s OUTPUT;
EXEC #renovar_hasta @s, 2, '2026-11-10';
EXEC usp_suspender_suscripcion @id_suscripcion = @s, @fecha = '2026-11-20', @observacion = N'Pago rechazado por el banco';

-- Cliente 7, Distribuidora El Ángel: planes empresariales anuales.
EXEC usp_contratar_suscripcion @id_cliente = 7, @id_modalidad = 14, @id_tipo_pago = 3, @fecha = '2026-01-20', @id_suscripcion = @s OUTPUT;
EXEC usp_contratar_suscripcion @id_cliente = 7, @id_modalidad = 5,  @id_tipo_pago = 3, @fecha = '2026-01-25', @id_suscripcion = @s OUTPUT;

-- Cliente 8, Unidad Educativa: AulaVirtual mensual, pasa a semestral y renueva.
EXEC usp_contratar_suscripcion @id_cliente = 8, @id_modalidad = 11, @id_tipo_pago = 3, @fecha = '2026-03-01', @id_suscripcion = @s OUTPUT;
EXEC #renovar_hasta @s, 3, '2026-04-30';
EXEC usp_modificar_suscripcion @id_suscripcion = @s, @id_modalidad_nueva = 12, @id_tipo_pago = 3, @fecha = '2026-05-01', @observacion = N'Plan semestral para el periodo lectivo';
EXEC usp_renovar_suscripcion @id_suscripcion = @s, @id_tipo_pago = 3, @fecha = '2026-11-01';

-- Cliente 9, Kevin: CineStream premium, cancela en agosto y deja de ser cliente activo.
EXEC usp_contratar_suscripcion @id_cliente = 9, @id_modalidad = 8, @id_tipo_pago = 1, @fecha = '2026-05-18', @id_suscripcion = @s OUTPUT;
EXEC #renovar_hasta @s, 1, '2026-08-17';
EXEC usp_cancelar_suscripcion @id_suscripcion = @s, @fecha = '2026-08-30', @observacion = N'Cierra su cuenta';
UPDATE cliente SET cliente_activo = 0 WHERE id_cliente = 9;

-- Cliente 10, Diana: NubeDrive premium anual y MúsicaYa individual.
EXEC usp_contratar_suscripcion @id_cliente = 10, @id_modalidad = 3, @id_tipo_pago = 4, @fecha = '2026-06-02', @id_suscripcion = @s OUTPUT;
EXEC usp_contratar_suscripcion @id_cliente = 10, @id_modalidad = 9, @id_tipo_pago = 4, @fecha = '2026-06-05', @id_suscripcion = @s OUTPUT;
EXEC #renovar_hasta @s, 4, @hoy;
GO

DROP PROCEDURE #renovar_hasta;
GO

/* ---------------------------------------------------------------------
   REGISTRO DE USO: un registro por mes de cada suscripción, desde su
   inicio hasta hoy (o hasta su cancelación). La métrica depende de la
   categoría del servicio. Los valores son fijos para que todos tengan
   los mismos resultados.
   --------------------------------------------------------------------- */
DECLARE @hoy DATE = '2026-11-24';

WITH limites AS (
    SELECT s.id_suscripcion,
           s.fecha_inicio,
           CASE WHEN s.id_estado_suscripcion = 3
                THEN (SELECT CAST(MAX(o.fecha_operacion) AS DATE)
                      FROM operacion_suscripcion o WHERE o.id_suscripcion = s.id_suscripcion)
                ELSE @hoy END AS hasta
    FROM suscripcion s
),
meses AS (
    SELECT id_suscripcion, fecha_inicio AS mes, hasta FROM limites
    UNION ALL
    SELECT id_suscripcion, DATEADD(MONTH, 1, mes), hasta
    FROM meses
    WHERE DATEADD(MONTH, 1, mes) <= hasta
)
INSERT INTO registro_uso (id_suscripcion, id_tipo_metrica, fecha_uso, valor)
SELECT me.id_suscripcion,
       tm.id_tipo_metrica,
       DATEADD(DAY, 20, me.mes),
       CASE tm.unidad
            WHEN N'GB'         THEN 5 + ABS(CHECKSUM(me.id_suscripcion, me.mes)) % 95
            WHEN N'horas'      THEN 3 + ABS(CHECKSUM(me.id_suscripcion, me.mes)) % 60
            WHEN N'lecciones'  THEN 1 + ABS(CHECKSUM(me.id_suscripcion, me.mes)) % 20
            ELSE                    2 + ABS(CHECKSUM(me.id_suscripcion, me.mes)) % 40
       END
FROM meses me
JOIN suscripcion s ON s.id_suscripcion = me.id_suscripcion
JOIN modalidad   m ON m.id_modalidad   = s.id_modalidad
JOIN servicio   sv ON sv.id_servicio   = m.id_servicio
JOIN categoria   c ON c.id_categoria   = sv.id_categoria
JOIN (VALUES (N'Almacenamiento en la nube', N'Almacenamiento usado'),
             (N'Entretenimiento',           N'Horas de reproducción'),
             (N'Educación en línea',        N'Lecciones completadas'),
             (N'Productividad',             N'Documentos creados')) AS mapa (categoria, metrica)
     ON mapa.categoria = c.nombre
JOIN tipo_metrica tm ON tm.nombre = mapa.metrica
WHERE DATEADD(DAY, 20, me.mes) <= me.hasta
OPTION (MAXRECURSION 200);
GO

/* ---------------------------------------------------------------------
   RESUMEN: cuántos registros quedaron en cada tabla
   --------------------------------------------------------------------- */
SELECT 'categoria' AS tabla, COUNT(*) AS registros FROM categoria
UNION ALL SELECT 'estado_suscripcion',    COUNT(*) FROM estado_suscripcion
UNION ALL SELECT 'tipo_operacion',        COUNT(*) FROM tipo_operacion
UNION ALL SELECT 'tipo_pago',             COUNT(*) FROM tipo_pago
UNION ALL SELECT 'tipo_metrica',          COUNT(*) FROM tipo_metrica
UNION ALL SELECT 'cliente',               COUNT(*) FROM cliente
UNION ALL SELECT 'servicio',              COUNT(*) FROM servicio
UNION ALL SELECT 'modalidad',             COUNT(*) FROM modalidad
UNION ALL SELECT 'suscripcion',           COUNT(*) FROM suscripcion
UNION ALL SELECT 'operacion_suscripcion', COUNT(*) FROM operacion_suscripcion
UNION ALL SELECT 'pago',                  COUNT(*) FROM pago
UNION ALL SELECT 'registro_uso',          COUNT(*) FROM registro_uso;
GO
