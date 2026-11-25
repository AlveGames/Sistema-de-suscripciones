/* =====================================================================
   PLATAFORMA DE SERVICIOS POR SUSCRIPCIÓN  -  Grupo 2, Base de Datos (A1)
   01_estructura.sql : base de datos, tablas, claves y restricciones

   Ejecutar en SSMS en este orden:
     01_estructura.sql  ->  02_procedimientos.sql  ->  03_datos.sql
   Este script BORRA la base si ya existe y la crea de nuevo,
   así todos quedan con la misma versión.
   ===================================================================== */

USE master;
GO

IF DB_ID(N'PlataformaSuscripciones') IS NOT NULL
BEGIN
    ALTER DATABASE PlataformaSuscripciones SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE PlataformaSuscripciones;
END
GO

CREATE DATABASE PlataformaSuscripciones;
GO

USE PlataformaSuscripciones;
GO

/* ---------------------------------------------------------------------
   TABLAS PARAMÉTRICAS (catálogos)
   --------------------------------------------------------------------- */

CREATE TABLE categoria (
    id_categoria        INT IDENTITY(1,1) NOT NULL,
    nombre              NVARCHAR(80)      NOT NULL,
    CONSTRAINT PK_categoria        PRIMARY KEY (id_categoria),
    CONSTRAINT UQ_categoria_nombre UNIQUE (nombre)
);

CREATE TABLE estado_suscripcion (
    id_estado_suscripcion INT IDENTITY(1,1) NOT NULL,
    nombre                NVARCHAR(30)      NOT NULL,
    CONSTRAINT PK_estado_suscripcion        PRIMARY KEY (id_estado_suscripcion),
    CONSTRAINT UQ_estado_suscripcion_nombre UNIQUE (nombre)
);

CREATE TABLE tipo_operacion (
    id_tipo_operacion   INT IDENTITY(1,1) NOT NULL,
    nombre_operacion    NVARCHAR(30)      NOT NULL,
    descripcion         NVARCHAR(200)     NULL,
    CONSTRAINT PK_tipo_operacion        PRIMARY KEY (id_tipo_operacion),
    CONSTRAINT UQ_tipo_operacion_nombre UNIQUE (nombre_operacion)
);

CREATE TABLE tipo_pago (
    id_tipo_pago        INT IDENTITY(1,1) NOT NULL,
    nombre_tipo_metodo  NVARCHAR(50)      NOT NULL,
    CONSTRAINT PK_tipo_pago        PRIMARY KEY (id_tipo_pago),
    CONSTRAINT UQ_tipo_pago_nombre UNIQUE (nombre_tipo_metodo)
);

CREATE TABLE tipo_metrica (
    id_tipo_metrica     INT IDENTITY(1,1) NOT NULL,
    nombre              NVARCHAR(50)      NOT NULL,
    unidad              NVARCHAR(20)      NOT NULL,
    CONSTRAINT PK_tipo_metrica        PRIMARY KEY (id_tipo_metrica),
    CONSTRAINT UQ_tipo_metrica_nombre UNIQUE (nombre)
);

/* ---------------------------------------------------------------------
   TABLAS MAESTRAS
   --------------------------------------------------------------------- */

CREATE TABLE cliente (
    id_cliente          INT IDENTITY(1,1) NOT NULL,
    nombre              NVARCHAR(150)     NOT NULL,
    documento           VARCHAR(13)       NOT NULL,   -- cédula (10) o RUC (13)
    correo              NVARCHAR(120)     NOT NULL,
    telefono            VARCHAR(15)       NULL,
    fecha_registro      DATE              NOT NULL CONSTRAINT DF_cliente_fecha_registro DEFAULT (CAST(GETDATE() AS DATE)),
    cliente_activo      BIT               NOT NULL CONSTRAINT DF_cliente_activo DEFAULT (1),
    tipo_cliente        NVARCHAR(15)      NOT NULL,
    CONSTRAINT PK_cliente           PRIMARY KEY (id_cliente),
    CONSTRAINT UQ_cliente_documento UNIQUE (documento),
    CONSTRAINT CK_cliente_tipo      CHECK (tipo_cliente IN (N'Persona', N'Organización')),
    CONSTRAINT CK_cliente_correo    CHECK (correo LIKE N'%_@_%._%')
);

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

/* ---------------------------------------------------------------------
   TABLAS TRANSACCIONALES
   --------------------------------------------------------------------- */

-- Tabla puente de la relación N:M cliente - modalidad.
-- Guarda la modalidad y el estado VIGENTES; el historial va en operacion_suscripcion.
CREATE TABLE suscripcion (
    id_suscripcion        INT IDENTITY(1,1) NOT NULL,
    id_cliente            INT               NOT NULL,
    id_modalidad          INT               NOT NULL,
    id_estado_suscripcion INT               NOT NULL,
    fecha_inicio          DATE              NOT NULL,
    fecha_fin             DATE              NOT NULL,
    CONSTRAINT PK_suscripcion          PRIMARY KEY (id_suscripcion),
    CONSTRAINT FK_suscripcion_cliente  FOREIGN KEY (id_cliente)            REFERENCES cliente (id_cliente),
    CONSTRAINT FK_suscripcion_modalidad FOREIGN KEY (id_modalidad)         REFERENCES modalidad (id_modalidad),
    CONSTRAINT FK_suscripcion_estado   FOREIGN KEY (id_estado_suscripcion) REFERENCES estado_suscripcion (id_estado_suscripcion),
    CONSTRAINT CK_suscripcion_fechas   CHECK (fecha_fin >= fecha_inicio)
);

-- Historial de todo lo que le pasa a una suscripción.
CREATE TABLE operacion_suscripcion (
    id_operacion_suscripcion INT IDENTITY(1,1) NOT NULL,
    id_suscripcion           INT               NOT NULL,
    id_tipo_operacion        INT               NOT NULL,
    id_modalidad_anterior    INT               NULL,       -- NULL solo en la contratación
    id_modalidad_nueva       INT               NOT NULL,
    precio_aplicado          DECIMAL(10,2)     NULL,       -- precio congelado del momento
    fecha_inicio_periodo     DATE              NULL,
    fecha_fin_periodo        DATE              NULL,
    fecha_operacion          DATETIME2(0)      NOT NULL CONSTRAINT DF_operacion_fecha DEFAULT (SYSDATETIME()),
    observacion              NVARCHAR(300)     NULL,
    CONSTRAINT PK_operacion_suscripcion   PRIMARY KEY (id_operacion_suscripcion),
    CONSTRAINT FK_operacion_suscripcion   FOREIGN KEY (id_suscripcion)        REFERENCES suscripcion (id_suscripcion),
    CONSTRAINT FK_operacion_tipo          FOREIGN KEY (id_tipo_operacion)     REFERENCES tipo_operacion (id_tipo_operacion),
    CONSTRAINT FK_operacion_mod_anterior  FOREIGN KEY (id_modalidad_anterior) REFERENCES modalidad (id_modalidad),
    CONSTRAINT FK_operacion_mod_nueva     FOREIGN KEY (id_modalidad_nueva)    REFERENCES modalidad (id_modalidad),
    CONSTRAINT CK_operacion_precio        CHECK (precio_aplicado IS NULL OR precio_aplicado >= 0),
    CONSTRAINT CK_operacion_periodo       CHECK (fecha_fin_periodo >= fecha_inicio_periodo),
    -- 1 = Contratación: sin modalidad anterior. Las demás operaciones sí la tienen.
    CONSTRAINT CK_operacion_anterior      CHECK (
           (id_tipo_operacion = 1  AND id_modalidad_anterior IS NULL)
        OR (id_tipo_operacion <> 1 AND id_modalidad_anterior IS NOT NULL)),
    -- 1,2,3 (Contratación, Renovación, Modificación) cobran y tienen periodo.
    -- 4,5,6 (Suspensión, Reactivación, Cancelación) no cobran ni tienen periodo.
    CONSTRAINT CK_operacion_cobro         CHECK (
           (id_tipo_operacion IN (1,2,3) AND precio_aplicado IS NOT NULL
                AND fecha_inicio_periodo IS NOT NULL AND fecha_fin_periodo IS NOT NULL)
        OR (id_tipo_operacion IN (4,5,6) AND precio_aplicado IS NULL
                AND fecha_inicio_periodo IS NULL AND fecha_fin_periodo IS NULL))
);

CREATE TABLE pago (
    id_pago                  INT IDENTITY(1,1) NOT NULL,
    id_operacion_suscripcion INT               NOT NULL,
    id_tipo_pago             INT               NOT NULL,
    fecha_pago               DATETIME2(0)      NOT NULL CONSTRAINT DF_pago_fecha DEFAULT (SYSDATETIME()),
    monto                    DECIMAL(10,2)     NOT NULL,
    CONSTRAINT PK_pago            PRIMARY KEY (id_pago),
    CONSTRAINT FK_pago_operacion  FOREIGN KEY (id_operacion_suscripcion) REFERENCES operacion_suscripcion (id_operacion_suscripcion),
    CONSTRAINT FK_pago_tipo_pago  FOREIGN KEY (id_tipo_pago)             REFERENCES tipo_pago (id_tipo_pago),
    CONSTRAINT CK_pago_monto      CHECK (monto > 0)
);

CREATE TABLE registro_uso (
    id_uso              INT IDENTITY(1,1) NOT NULL,
    id_suscripcion      INT               NOT NULL,
    id_tipo_metrica     INT               NOT NULL,
    fecha_uso           DATE              NOT NULL,
    valor               DECIMAL(12,2)     NOT NULL,
    CONSTRAINT PK_registro_uso          PRIMARY KEY (id_uso),
    CONSTRAINT FK_uso_suscripcion       FOREIGN KEY (id_suscripcion)  REFERENCES suscripcion (id_suscripcion),
    CONSTRAINT FK_uso_tipo_metrica      FOREIGN KEY (id_tipo_metrica) REFERENCES tipo_metrica (id_tipo_metrica),
    CONSTRAINT CK_uso_valor             CHECK (valor >= 0)
);
GO

/* ---------------------------------------------------------------------
   VALORES FIJOS DE LOS CATÁLOGOS QUE USAN LAS REGLAS
   Los ids no deben cambiar: las restricciones y los procedimientos los usan.
   --------------------------------------------------------------------- */

SET IDENTITY_INSERT estado_suscripcion ON;
INSERT INTO estado_suscripcion (id_estado_suscripcion, nombre) VALUES
    (1, N'Activa'),
    (2, N'Suspendida'),
    (3, N'Cancelada');
SET IDENTITY_INSERT estado_suscripcion OFF;

SET IDENTITY_INSERT tipo_operacion ON;
INSERT INTO tipo_operacion (id_tipo_operacion, nombre_operacion, descripcion) VALUES
    (1, N'Contratación', N'El cliente contrata una modalidad por primera vez'),
    (2, N'Renovación',   N'Se extiende la suscripción un periodo más con la misma modalidad'),
    (3, N'Modificación', N'El cliente cambia a otra modalidad del mismo servicio'),
    (4, N'Suspensión',   N'La suscripción se pausa temporalmente'),
    (5, N'Reactivación', N'Una suscripción suspendida vuelve a estar activa'),
    (6, N'Cancelación',  N'La suscripción termina');
SET IDENTITY_INSERT tipo_operacion OFF;
GO

/* ---------------------------------------------------------------------
   ÍNDICE ÚNICO FILTRADO
   Un cliente no puede tener dos suscripciones ACTIVAS a la misma modalidad.
   Sí puede volver a contratarla después de cancelar (queda en el historial).
   --------------------------------------------------------------------- */

CREATE UNIQUE INDEX UX_suscripcion_activa
    ON suscripcion (id_cliente, id_modalidad)
    WHERE id_estado_suscripcion = 1;
GO

PRINT N'Estructura creada: 12 tablas.';
GO
