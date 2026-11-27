/* =====================================================================
   PLATAFORMA DE SERVICIOS POR SUSCRIPCIÓN  -  Grupo 2, Base de Datos (A1)
   04_consultas.sql : consultas del negocio            Responsable: Joel Lino

   Ejecutar en SSMS después de 01, 02 y 03.
   Cada consulta une por lo menos 3 tablas.
   En Django estas mismas consultas están en consultas/views.py;
   allá los parámetros se escriben %s en lugar de @variable.
   ===================================================================== */

USE PlataformaSuscripciones;
GO

/* ---------------------------------------------------------------------
   CONSULTA 1 - Historial de un cliente
   Pregunta: ¿Qué operaciones hizo el cliente, en qué fecha, qué plan tenía
   antes y después, qué precio se le aplicó y cuánto pagó?
   Tablas: cliente, suscripcion, operacion_suscripcion, tipo_operacion,
           modalidad (anterior y nueva), servicio, pago
   El plan anterior va con LEFT JOIN porque en la contratación es NULL.
   El pago va con LEFT JOIN porque suspensión, reactivación y cancelación
   no cobran.
   --------------------------------------------------------------------- */
DECLARE @id_cliente INT = 1;   -- cambiar por el cliente que se quiere ver

SELECT
    o.fecha_operacion                               AS [Fecha],
    t.nombre_operacion                              AS [Operación],
    sv.nombre                                       AS [Servicio],
    ma.nombre_plan                                  AS [Plan anterior],
    mn.nombre_plan                                  AS [Plan nuevo],
    o.precio_aplicado                               AS [Precio aplicado],
    SUM(p.monto)                                    AS [Monto pagado]
FROM cliente c
JOIN suscripcion s             ON s.id_cliente         = c.id_cliente
JOIN operacion_suscripcion o   ON o.id_suscripcion     = s.id_suscripcion
JOIN tipo_operacion t          ON t.id_tipo_operacion  = o.id_tipo_operacion
JOIN modalidad mn              ON mn.id_modalidad      = o.id_modalidad_nueva
JOIN servicio sv               ON sv.id_servicio       = mn.id_servicio
LEFT JOIN modalidad ma         ON ma.id_modalidad      = o.id_modalidad_anterior
LEFT JOIN pago p               ON p.id_operacion_suscripcion = o.id_operacion_suscripcion
WHERE c.id_cliente = @id_cliente
GROUP BY o.id_operacion_suscripcion, o.fecha_operacion, t.nombre_operacion,
         sv.nombre, ma.nombre_plan, mn.nombre_plan, o.precio_aplicado
ORDER BY o.fecha_operacion, o.id_operacion_suscripcion;
GO

/* ---------------------------------------------------------------------
   CONSULTA 2 - Ingresos por servicio y por mes
   Pregunta: ¿Cuánto dinero ingresó cada servicio en cada mes?
   Tablas: pago, operacion_suscripcion, modalidad, servicio
   El servicio sale de la modalidad NUEVA de la operación que se cobró.
   --------------------------------------------------------------------- */
SELECT
    sv.nombre                   AS [Servicio],
    YEAR(p.fecha_pago)          AS [Año],
    MONTH(p.fecha_pago)         AS [Mes],
    COUNT(p.id_pago)            AS [Pagos],
    SUM(p.monto)                AS [Ingresos]
FROM pago p
JOIN operacion_suscripcion o   ON o.id_operacion_suscripcion = p.id_operacion_suscripcion
JOIN modalidad m               ON m.id_modalidad = o.id_modalidad_nueva
JOIN servicio sv               ON sv.id_servicio = m.id_servicio
-- WHERE YEAR(p.fecha_pago) = 2026      -- filtro opcional por año
GROUP BY sv.nombre, YEAR(p.fecha_pago), MONTH(p.fecha_pago)
ORDER BY [Año], [Mes], sv.nombre;
GO

/* ---------------------------------------------------------------------
   CONSULTA 3 - Suscripciones activas por categoría y servicio
   Pregunta: ¿Cuántas suscripciones activas tiene cada servicio, agrupado
   por categoría, incluyendo los servicios que no tienen ninguna?
   Tablas: categoria, servicio, modalidad, suscripcion
   LEFT JOIN para que aparezcan los servicios sin suscripciones (cuentan 0).
   La condición de "activa" (id_estado_suscripcion = 1) va en el ON y no en
   el WHERE; si fuera en el WHERE se perderían los servicios con 0.
   --------------------------------------------------------------------- */
SELECT
    c.nombre                            AS [Categoría],
    sv.nombre                           AS [Servicio],
    sv.estado                           AS [Estado del servicio],
    COUNT(DISTINCT m.id_modalidad)      AS [Planes],
    COUNT(s.id_suscripcion)             AS [Suscripciones activas]
FROM categoria c
JOIN servicio sv               ON sv.id_categoria = c.id_categoria
LEFT JOIN modalidad m          ON m.id_servicio   = sv.id_servicio
LEFT JOIN suscripcion s        ON s.id_modalidad  = m.id_modalidad
                              AND s.id_estado_suscripcion = 1      -- 1 = Activa
GROUP BY c.nombre, sv.nombre, sv.estado
ORDER BY c.nombre, sv.nombre;
GO

/* ---------------------------------------------------------------------
   CONSULTA 4 - Uso por servicio y tipo de métrica
   Pregunta: ¿Cuánto se usa cada servicio según su métrica, en total y en
   promedio por registro?
   Tablas: registro_uso, tipo_metrica, suscripcion, modalidad, servicio
   --------------------------------------------------------------------- */
SELECT
    sv.nombre                               AS [Servicio],
    tm.nombre                               AS [Métrica],
    tm.unidad                               AS [Unidad],
    COUNT(r.id_uso)                         AS [Registros],
    SUM(r.valor)                            AS [Total],
    CAST(AVG(r.valor) AS DECIMAL(12,2))     AS [Promedio]
FROM registro_uso r
JOIN tipo_metrica tm           ON tm.id_tipo_metrica = r.id_tipo_metrica
JOIN suscripcion s             ON s.id_suscripcion   = r.id_suscripcion
JOIN modalidad m               ON m.id_modalidad     = s.id_modalidad
JOIN servicio sv               ON sv.id_servicio     = m.id_servicio
GROUP BY sv.nombre, tm.nombre, tm.unidad
ORDER BY sv.nombre, tm.nombre;
GO
