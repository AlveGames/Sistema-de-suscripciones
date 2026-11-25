/* =====================================================================
   PLATAFORMA DE SERVICIOS POR SUSCRIPCIÓN  -  Grupo 2, Base de Datos (A1)
   02_procedimientos.sql : procedimientos almacenados y triggers

   Cada operación del negocio es un procedimiento que, en UNA sola
   transacción, valida las reglas, registra la operación en el historial,
   registra el pago (si la operación cobra) y actualiza la suscripción.

   Todos aceptan @fecha opcional (por defecto, hoy). Sirve para cargar
   historiales con fechas pasadas en 03_datos.sql.
   ===================================================================== */

USE PlataformaSuscripciones;
GO
SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

/* ---------------------------------------------------------------------
   1. CONTRATAR
   --------------------------------------------------------------------- */
CREATE OR ALTER PROCEDURE usp_contratar_suscripcion
    @id_cliente      INT,
    @id_modalidad    INT,
    @id_tipo_pago    INT,
    @fecha           DATE          = NULL,
    @observacion     NVARCHAR(300) = NULL,
    @id_suscripcion  INT           = NULL OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    SET @fecha = ISNULL(@fecha, CAST(GETDATE() AS DATE));
    DECLARE @momento DATETIME2(0) =
        CASE WHEN @fecha = CAST(GETDATE() AS DATE) THEN SYSDATETIME() ELSE CAST(@fecha AS DATETIME2(0)) END;

    IF NOT EXISTS (SELECT 1 FROM cliente WHERE id_cliente = @id_cliente AND cliente_activo = 1)
        THROW 50001, N'El cliente no existe o no está activo.', 1;

    IF NOT EXISTS (SELECT 1 FROM modalidad m
                   JOIN servicio s ON s.id_servicio = m.id_servicio
                   WHERE m.id_modalidad = @id_modalidad AND s.estado = N'Activo')
        THROW 50002, N'La modalidad no existe o su servicio está inactivo.', 1;

    IF NOT EXISTS (SELECT 1 FROM tipo_pago WHERE id_tipo_pago = @id_tipo_pago)
        THROW 50003, N'El tipo de pago no existe.', 1;

    IF EXISTS (SELECT 1 FROM suscripcion
               WHERE id_cliente = @id_cliente AND id_modalidad = @id_modalidad
                 AND id_estado_suscripcion IN (1, 2))
        THROW 50004, N'El cliente ya tiene una suscripción activa o suspendida a esta modalidad.', 1;

    DECLARE @duracion INT, @precio DECIMAL(10,2);
    SELECT @duracion = duracion_servicio, @precio = precio_base
    FROM modalidad WHERE id_modalidad = @id_modalidad;

    DECLARE @fin DATE = DATEADD(MONTH, @duracion, @fecha);
    DECLARE @id_operacion INT;

    BEGIN TRY
        BEGIN TRANSACTION;

        INSERT INTO suscripcion (id_cliente, id_modalidad, id_estado_suscripcion, fecha_inicio, fecha_fin)
        VALUES (@id_cliente, @id_modalidad, 1, @fecha, @fin);
        SET @id_suscripcion = SCOPE_IDENTITY();

        INSERT INTO operacion_suscripcion
            (id_suscripcion, id_tipo_operacion, id_modalidad_anterior, id_modalidad_nueva,
             precio_aplicado, fecha_inicio_periodo, fecha_fin_periodo, fecha_operacion, observacion)
        VALUES
            (@id_suscripcion, 1, NULL, @id_modalidad,
             @precio, @fecha, @fin, @momento, @observacion);
        SET @id_operacion = SCOPE_IDENTITY();

        IF @precio > 0
            INSERT INTO pago (id_operacion_suscripcion, id_tipo_pago, fecha_pago, monto)
            VALUES (@id_operacion, @id_tipo_pago, @momento, @precio);

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END
GO

/* ---------------------------------------------------------------------
   2. RENOVAR  (el nuevo periodo empieza donde termina el vigente)
   --------------------------------------------------------------------- */
CREATE OR ALTER PROCEDURE usp_renovar_suscripcion
    @id_suscripcion  INT,
    @id_tipo_pago    INT,
    @fecha           DATE          = NULL,
    @observacion     NVARCHAR(300) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    SET @fecha = ISNULL(@fecha, CAST(GETDATE() AS DATE));
    DECLARE @momento DATETIME2(0) =
        CASE WHEN @fecha = CAST(GETDATE() AS DATE) THEN SYSDATETIME() ELSE CAST(@fecha AS DATETIME2(0)) END;

    IF NOT EXISTS (SELECT 1 FROM suscripcion WHERE id_suscripcion = @id_suscripcion AND id_estado_suscripcion = 1)
        THROW 50010, N'Solo se puede renovar una suscripción activa.', 1;

    IF NOT EXISTS (SELECT 1 FROM tipo_pago WHERE id_tipo_pago = @id_tipo_pago)
        THROW 50003, N'El tipo de pago no existe.', 1;

    IF @fecha < (SELECT CAST(MAX(fecha_operacion) AS DATE) FROM operacion_suscripcion WHERE id_suscripcion = @id_suscripcion)
        THROW 50005, N'La fecha no puede ser anterior a la última operación de la suscripción.', 1;

    DECLARE @id_modalidad INT, @inicio DATE;
    SELECT @id_modalidad = id_modalidad, @inicio = fecha_fin
    FROM suscripcion WHERE id_suscripcion = @id_suscripcion;

    DECLARE @duracion INT, @precio DECIMAL(10,2);
    SELECT @duracion = duracion_servicio, @precio = precio_base
    FROM modalidad WHERE id_modalidad = @id_modalidad;

    DECLARE @fin DATE = DATEADD(MONTH, @duracion, @inicio);
    DECLARE @id_operacion INT;

    BEGIN TRY
        BEGIN TRANSACTION;

        INSERT INTO operacion_suscripcion
            (id_suscripcion, id_tipo_operacion, id_modalidad_anterior, id_modalidad_nueva,
             precio_aplicado, fecha_inicio_periodo, fecha_fin_periodo, fecha_operacion, observacion)
        VALUES
            (@id_suscripcion, 2, @id_modalidad, @id_modalidad,
             @precio, @inicio, @fin, @momento, @observacion);
        SET @id_operacion = SCOPE_IDENTITY();

        IF @precio > 0
            INSERT INTO pago (id_operacion_suscripcion, id_tipo_pago, fecha_pago, monto)
            VALUES (@id_operacion, @id_tipo_pago, @momento, @precio);

        UPDATE suscripcion SET fecha_fin = @fin WHERE id_suscripcion = @id_suscripcion;

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END
GO

/* ---------------------------------------------------------------------
   3. MODIFICAR  (cambio a otra modalidad del MISMO servicio;
                  el nuevo periodo empieza en la fecha del cambio)
   --------------------------------------------------------------------- */
CREATE OR ALTER PROCEDURE usp_modificar_suscripcion
    @id_suscripcion      INT,
    @id_modalidad_nueva  INT,
    @id_tipo_pago        INT,
    @fecha               DATE          = NULL,
    @observacion         NVARCHAR(300) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    SET @fecha = ISNULL(@fecha, CAST(GETDATE() AS DATE));
    DECLARE @momento DATETIME2(0) =
        CASE WHEN @fecha = CAST(GETDATE() AS DATE) THEN SYSDATETIME() ELSE CAST(@fecha AS DATETIME2(0)) END;

    IF NOT EXISTS (SELECT 1 FROM suscripcion WHERE id_suscripcion = @id_suscripcion AND id_estado_suscripcion = 1)
        THROW 50011, N'Solo se puede modificar una suscripción activa.', 1;

    IF NOT EXISTS (SELECT 1 FROM tipo_pago WHERE id_tipo_pago = @id_tipo_pago)
        THROW 50003, N'El tipo de pago no existe.', 1;

    IF @fecha < (SELECT CAST(MAX(fecha_operacion) AS DATE) FROM operacion_suscripcion WHERE id_suscripcion = @id_suscripcion)
        THROW 50005, N'La fecha no puede ser anterior a la última operación de la suscripción.', 1;

    DECLARE @id_cliente INT, @id_modalidad_actual INT;
    SELECT @id_cliente = id_cliente, @id_modalidad_actual = id_modalidad
    FROM suscripcion WHERE id_suscripcion = @id_suscripcion;

    IF @id_modalidad_nueva = @id_modalidad_actual
        THROW 50012, N'La nueva modalidad es igual a la actual.', 1;

    IF NOT EXISTS (SELECT 1 FROM modalidad mn
                   JOIN modalidad ma ON ma.id_modalidad = @id_modalidad_actual
                   WHERE mn.id_modalidad = @id_modalidad_nueva AND mn.id_servicio = ma.id_servicio)
        THROW 50013, N'La nueva modalidad debe pertenecer al mismo servicio de la suscripción.', 1;

    IF EXISTS (SELECT 1 FROM suscripcion
               WHERE id_cliente = @id_cliente AND id_modalidad = @id_modalidad_nueva
                 AND id_estado_suscripcion IN (1, 2) AND id_suscripcion <> @id_suscripcion)
        THROW 50004, N'El cliente ya tiene una suscripción activa o suspendida a esta modalidad.', 1;

    DECLARE @duracion INT, @precio DECIMAL(10,2);
    SELECT @duracion = duracion_servicio, @precio = precio_base
    FROM modalidad WHERE id_modalidad = @id_modalidad_nueva;

    DECLARE @fin DATE = DATEADD(MONTH, @duracion, @fecha);
    DECLARE @id_operacion INT;

    BEGIN TRY
        BEGIN TRANSACTION;

        INSERT INTO operacion_suscripcion
            (id_suscripcion, id_tipo_operacion, id_modalidad_anterior, id_modalidad_nueva,
             precio_aplicado, fecha_inicio_periodo, fecha_fin_periodo, fecha_operacion, observacion)
        VALUES
            (@id_suscripcion, 3, @id_modalidad_actual, @id_modalidad_nueva,
             @precio, @fecha, @fin, @momento, @observacion);
        SET @id_operacion = SCOPE_IDENTITY();

        IF @precio > 0
            INSERT INTO pago (id_operacion_suscripcion, id_tipo_pago, fecha_pago, monto)
            VALUES (@id_operacion, @id_tipo_pago, @momento, @precio);

        UPDATE suscripcion
        SET id_modalidad = @id_modalidad_nueva, fecha_fin = @fin
        WHERE id_suscripcion = @id_suscripcion;

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END
GO

/* ---------------------------------------------------------------------
   4. SUSPENDER  (no cobra)
   --------------------------------------------------------------------- */
CREATE OR ALTER PROCEDURE usp_suspender_suscripcion
    @id_suscripcion  INT,
    @fecha           DATE          = NULL,
    @observacion     NVARCHAR(300) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    SET @fecha = ISNULL(@fecha, CAST(GETDATE() AS DATE));
    DECLARE @momento DATETIME2(0) =
        CASE WHEN @fecha = CAST(GETDATE() AS DATE) THEN SYSDATETIME() ELSE CAST(@fecha AS DATETIME2(0)) END;

    IF NOT EXISTS (SELECT 1 FROM suscripcion WHERE id_suscripcion = @id_suscripcion AND id_estado_suscripcion = 1)
        THROW 50014, N'Solo se puede suspender una suscripción activa.', 1;

    IF @fecha < (SELECT CAST(MAX(fecha_operacion) AS DATE) FROM operacion_suscripcion WHERE id_suscripcion = @id_suscripcion)
        THROW 50005, N'La fecha no puede ser anterior a la última operación de la suscripción.', 1;

    DECLARE @id_modalidad INT = (SELECT id_modalidad FROM suscripcion WHERE id_suscripcion = @id_suscripcion);

    BEGIN TRY
        BEGIN TRANSACTION;

        INSERT INTO operacion_suscripcion
            (id_suscripcion, id_tipo_operacion, id_modalidad_anterior, id_modalidad_nueva,
             precio_aplicado, fecha_inicio_periodo, fecha_fin_periodo, fecha_operacion, observacion)
        VALUES
            (@id_suscripcion, 4, @id_modalidad, @id_modalidad,
             NULL, NULL, NULL, @momento, @observacion);

        UPDATE suscripcion SET id_estado_suscripcion = 2 WHERE id_suscripcion = @id_suscripcion;

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END
GO

/* ---------------------------------------------------------------------
   5. REACTIVAR  (no cobra)
   --------------------------------------------------------------------- */
CREATE OR ALTER PROCEDURE usp_reactivar_suscripcion
    @id_suscripcion  INT,
    @fecha           DATE          = NULL,
    @observacion     NVARCHAR(300) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    SET @fecha = ISNULL(@fecha, CAST(GETDATE() AS DATE));
    DECLARE @momento DATETIME2(0) =
        CASE WHEN @fecha = CAST(GETDATE() AS DATE) THEN SYSDATETIME() ELSE CAST(@fecha AS DATETIME2(0)) END;

    IF NOT EXISTS (SELECT 1 FROM suscripcion WHERE id_suscripcion = @id_suscripcion AND id_estado_suscripcion = 2)
        THROW 50015, N'Solo se puede reactivar una suscripción suspendida.', 1;

    IF @fecha < (SELECT CAST(MAX(fecha_operacion) AS DATE) FROM operacion_suscripcion WHERE id_suscripcion = @id_suscripcion)
        THROW 50005, N'La fecha no puede ser anterior a la última operación de la suscripción.', 1;

    DECLARE @id_modalidad INT = (SELECT id_modalidad FROM suscripcion WHERE id_suscripcion = @id_suscripcion);

    BEGIN TRY
        BEGIN TRANSACTION;

        INSERT INTO operacion_suscripcion
            (id_suscripcion, id_tipo_operacion, id_modalidad_anterior, id_modalidad_nueva,
             precio_aplicado, fecha_inicio_periodo, fecha_fin_periodo, fecha_operacion, observacion)
        VALUES
            (@id_suscripcion, 5, @id_modalidad, @id_modalidad,
             NULL, NULL, NULL, @momento, @observacion);

        UPDATE suscripcion SET id_estado_suscripcion = 1 WHERE id_suscripcion = @id_suscripcion;

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END
GO

/* ---------------------------------------------------------------------
   6. CANCELAR  (no cobra; la suscripción queda en el historial)
   --------------------------------------------------------------------- */
CREATE OR ALTER PROCEDURE usp_cancelar_suscripcion
    @id_suscripcion  INT,
    @fecha           DATE          = NULL,
    @observacion     NVARCHAR(300) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    SET @fecha = ISNULL(@fecha, CAST(GETDATE() AS DATE));
    DECLARE @momento DATETIME2(0) =
        CASE WHEN @fecha = CAST(GETDATE() AS DATE) THEN SYSDATETIME() ELSE CAST(@fecha AS DATETIME2(0)) END;

    IF NOT EXISTS (SELECT 1 FROM suscripcion WHERE id_suscripcion = @id_suscripcion AND id_estado_suscripcion IN (1, 2))
        THROW 50016, N'Solo se puede cancelar una suscripción activa o suspendida.', 1;

    IF @fecha < (SELECT CAST(MAX(fecha_operacion) AS DATE) FROM operacion_suscripcion WHERE id_suscripcion = @id_suscripcion)
        THROW 50005, N'La fecha no puede ser anterior a la última operación de la suscripción.', 1;

    DECLARE @id_modalidad INT = (SELECT id_modalidad FROM suscripcion WHERE id_suscripcion = @id_suscripcion);

    BEGIN TRY
        BEGIN TRANSACTION;

        INSERT INTO operacion_suscripcion
            (id_suscripcion, id_tipo_operacion, id_modalidad_anterior, id_modalidad_nueva,
             precio_aplicado, fecha_inicio_periodo, fecha_fin_periodo, fecha_operacion, observacion)
        VALUES
            (@id_suscripcion, 6, @id_modalidad, @id_modalidad,
             NULL, NULL, NULL, @momento, @observacion);

        UPDATE suscripcion SET id_estado_suscripcion = 3 WHERE id_suscripcion = @id_suscripcion;

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END
GO

/* ---------------------------------------------------------------------
   TRIGGERS: reglas que una CHECK no puede validar porque miran otra tabla.
   Protegen la base aunque alguien inserte o edite sin usar los procedimientos.
   --------------------------------------------------------------------- */

-- Un pago solo puede nacer de una operación que cobra (tiene precio_aplicado).
CREATE OR ALTER TRIGGER tr_pago_solo_operacion_con_cobro
ON pago
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    IF EXISTS (SELECT 1
               FROM inserted i
               JOIN operacion_suscripcion o ON o.id_operacion_suscripcion = i.id_operacion_suscripcion
               WHERE o.precio_aplicado IS NULL)
        THROW 50020, N'Solo se registran pagos de operaciones que generan cobro (contratación, renovación o modificación).', 1;
END
GO

-- La modalidad anterior y la nueva deben ser del mismo servicio que la suscripción.
CREATE OR ALTER TRIGGER tr_operacion_mismo_servicio
ON operacion_suscripcion
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    IF EXISTS (SELECT 1
               FROM inserted i
               JOIN suscripcion s      ON s.id_suscripcion = i.id_suscripcion
               JOIN modalidad   m_sus  ON m_sus.id_modalidad = s.id_modalidad
               JOIN modalidad   m_new  ON m_new.id_modalidad = i.id_modalidad_nueva
               LEFT JOIN modalidad m_ant ON m_ant.id_modalidad = i.id_modalidad_anterior
               WHERE m_new.id_servicio <> m_sus.id_servicio
                  OR (m_ant.id_modalidad IS NOT NULL AND m_ant.id_servicio <> m_new.id_servicio))
        THROW 50021, N'La modalidad anterior y la nueva deben pertenecer al mismo servicio de la suscripción.', 1;
END
GO

PRINT N'Procedimientos y triggers creados.';
GO
