"""
Consultas del negocio (Joel Lino).
Las 4 consultas son las mismas de sql/04_consultas.sql. Como usan JOIN y
GROUP BY se ejecutan directo con cursor. En Django los parámetros se
escriben %s (en SSMS eran @variable).
"""
from datetime import date, datetime
from decimal import Decimal

from django.db import connection
from django.shortcuts import render

from core.models import Cliente, Pago, Servicio

MESES = ["", "Enero", "Febrero", "Marzo", "Abril", "Mayo", "Junio", "Julio",
         "Agosto", "Septiembre", "Octubre", "Noviembre", "Diciembre"]

# Columnas que se muestran con signo de dólar.
COLUMNAS_DINERO = {"Precio aplicado", "Monto pagado", "Ingresos"}


# ---------------------------------------------------------------- utilidades
def ejecutar(sql, parametros=None):
    """Ejecuta una consulta y devuelve los nombres de columnas y las filas."""
    with connection.cursor() as cursor:
        cursor.execute(sql, parametros or [])
        columnas = [c[0] for c in cursor.description]
        filas = cursor.fetchall()
    return columnas, filas


def formatear(columna, valor):
    """Convierte un valor de la base en (texto, es_numero) para la tabla."""
    if valor is None:
        return "—", False
    if isinstance(valor, datetime):
        return valor.strftime("%d/%m/%Y %H:%M"), False
    if isinstance(valor, date):
        return valor.strftime("%d/%m/%Y"), False
    if isinstance(valor, (Decimal, float)) or (columna in COLUMNAS_DINERO and isinstance(valor, int)):
        texto = f"{valor:,.2f}"
        return (f"$ {texto}" if columna in COLUMNAS_DINERO else texto), True
    if isinstance(valor, int) and not isinstance(valor, bool):
        return str(valor), True
    return str(valor), False


def preparar(columnas, filas):
    """Arma la tabla: cada celda es (texto, es_numero). También dice qué
    encabezados van alineados a la derecha."""
    tabla = [[formatear(col, v) for col, v in zip(columnas, fila)] for fila in filas]
    numericas = [any(f[i][1] for f in tabla) for i in range(len(columnas))]
    encabezados = list(zip(columnas, numericas))
    return encabezados, tabla


def entero(valor):
    """Lee un parámetro GET como entero; si no es válido devuelve None."""
    try:
        return int(valor)
    except (TypeError, ValueError):
        return None


# ---------------------------------------------------------------- consultas
CONSULTAS = [
    {"numero": 1, "url": "consultas:consulta1",
     "titulo": "Historial de un cliente",
     "pregunta": "¿Qué operaciones hizo el cliente, qué plan tenía antes y después, "
                 "qué precio se le aplicó y cuánto pagó?"},
    {"numero": 2, "url": "consultas:consulta2",
     "titulo": "Ingresos por servicio y por mes",
     "pregunta": "¿Cuánto dinero ingresó cada servicio en cada mes?"},
    {"numero": 3, "url": "consultas:consulta3",
     "titulo": "Suscripciones activas por categoría y servicio",
     "pregunta": "¿Cuántas suscripciones activas tiene cada servicio, por categoría, "
                 "incluidos los servicios que no tienen ninguna?"},
    {"numero": 4, "url": "consultas:consulta4",
     "titulo": "Uso por servicio y tipo de métrica",
     "pregunta": "¿Cuánto se usa cada servicio según su métrica, en total y en promedio?"},
]

# 1. Historial de un cliente
SQL_HISTORIAL = """
    SELECT
        o.fecha_operacion   AS [Fecha],
        t.nombre_operacion  AS [Operación],
        sv.nombre           AS [Servicio],
        ma.nombre_plan      AS [Plan anterior],
        mn.nombre_plan      AS [Plan nuevo],
        o.precio_aplicado   AS [Precio aplicado],
        SUM(p.monto)        AS [Monto pagado]
    FROM cliente c
    JOIN suscripcion s            ON s.id_cliente        = c.id_cliente
    JOIN operacion_suscripcion o  ON o.id_suscripcion    = s.id_suscripcion
    JOIN tipo_operacion t         ON t.id_tipo_operacion = o.id_tipo_operacion
    JOIN modalidad mn             ON mn.id_modalidad     = o.id_modalidad_nueva
    JOIN servicio sv              ON sv.id_servicio      = mn.id_servicio
    LEFT JOIN modalidad ma        ON ma.id_modalidad     = o.id_modalidad_anterior
    LEFT JOIN pago p              ON p.id_operacion_suscripcion = o.id_operacion_suscripcion
    WHERE c.id_cliente = %s
    GROUP BY o.id_operacion_suscripcion, o.fecha_operacion, t.nombre_operacion,
             sv.nombre, ma.nombre_plan, mn.nombre_plan, o.precio_aplicado
    ORDER BY o.fecha_operacion, o.id_operacion_suscripcion
"""

# 2. Ingresos por servicio y por mes ({filtro} se reemplaza por el WHERE del año)
SQL_INGRESOS = """
    SELECT
        sv.nombre            AS [Servicio],
        YEAR(p.fecha_pago)   AS [Año],
        MONTH(p.fecha_pago)  AS [Mes],
        COUNT(p.id_pago)     AS [Pagos],
        SUM(p.monto)         AS [Ingresos]
    FROM pago p
    JOIN operacion_suscripcion o  ON o.id_operacion_suscripcion = p.id_operacion_suscripcion
    JOIN modalidad m              ON m.id_modalidad = o.id_modalidad_nueva
    JOIN servicio sv              ON sv.id_servicio = m.id_servicio
    {filtro}
    GROUP BY sv.nombre, YEAR(p.fecha_pago), MONTH(p.fecha_pago)
    ORDER BY YEAR(p.fecha_pago), MONTH(p.fecha_pago), sv.nombre
"""

# 3. Suscripciones activas por categoría y servicio (LEFT JOIN: salen los que tienen 0)
SQL_ACTIVAS = """
    SELECT
        c.nombre                        AS [Categoría],
        sv.nombre                       AS [Servicio],
        sv.estado                       AS [Estado del servicio],
        COUNT(DISTINCT m.id_modalidad)  AS [Planes],
        COUNT(s.id_suscripcion)         AS [Suscripciones activas]
    FROM categoria c
    JOIN servicio sv          ON sv.id_categoria = c.id_categoria
    LEFT JOIN modalidad m     ON m.id_servicio   = sv.id_servicio
    LEFT JOIN suscripcion s   ON s.id_modalidad  = m.id_modalidad
                             AND s.id_estado_suscripcion = 1
    GROUP BY c.nombre, sv.nombre, sv.estado
    ORDER BY c.nombre, sv.nombre
"""

# 4. Uso por servicio y tipo de métrica ({filtro} se reemplaza por el WHERE del servicio)
SQL_USO = """
    SELECT
        sv.nombre                            AS [Servicio],
        tm.nombre                            AS [Métrica],
        tm.unidad                            AS [Unidad],
        COUNT(r.id_uso)                      AS [Registros],
        SUM(r.valor)                         AS [Total],
        CAST(AVG(r.valor) AS DECIMAL(12,2))  AS [Promedio]
    FROM registro_uso r
    JOIN tipo_metrica tm  ON tm.id_tipo_metrica = r.id_tipo_metrica
    JOIN suscripcion s    ON s.id_suscripcion   = r.id_suscripcion
    JOIN modalidad m      ON m.id_modalidad     = s.id_modalidad
    JOIN servicio sv      ON sv.id_servicio     = m.id_servicio
    {filtro}
    GROUP BY sv.nombre, tm.nombre, tm.unidad
    ORDER BY sv.nombre, tm.nombre
"""


# ---------------------------------------------------------------- vistas
def mostrar(request, numero, columnas, filas, **extra):
    """Renderiza la página de resultado de una consulta."""
    info = CONSULTAS[numero - 1]
    encabezados, tabla = preparar(columnas, filas)
    contexto = {
        "titulo": info["titulo"],
        "pregunta": info["pregunta"],
        "numero": numero,
        "encabezados": encabezados,
        "filas": tabla,
    }
    contexto.update(extra)
    return render(request, "consultas/resultado.html", contexto)


def index(request):
    return render(request, "consultas/index.html", {"consultas": CONSULTAS})


def consulta1(request):
    id_cliente = entero(request.GET.get("cliente"))
    columnas, filas = ([], [])
    if id_cliente:
        columnas, filas = ejecutar(SQL_HISTORIAL, [id_cliente])
    return mostrar(request, 1, columnas, filas,
                   clientes=Cliente.objects.all(),
                   cliente_elegido=id_cliente,
                   esperando_filtro=not id_cliente)


def consulta2(request):
    anio = entero(request.GET.get("anio"))
    if anio:
        columnas, filas = ejecutar(SQL_INGRESOS.format(filtro="WHERE YEAR(p.fecha_pago) = %s"), [anio])
    else:
        columnas, filas = ejecutar(SQL_INGRESOS.format(filtro=""))
    # El mes llega como número: se muestra con su nombre.
    i = columnas.index("Mes")
    filas = [fila[:i] + (MESES[fila[i]],) + fila[i + 1:] for fila in filas]
    anios = sorted({f.year for f in Pago.objects.values_list("fecha_pago", flat=True)}, reverse=True)
    total = sum(fila[columnas.index("Ingresos")] for fila in filas) if filas else 0
    return mostrar(request, 2, columnas, filas,
                   anios=anios, anio_elegido=anio,
                   total=f"$ {total:,.2f}")


def consulta3(request):
    columnas, filas = ejecutar(SQL_ACTIVAS)
    return mostrar(request, 3, columnas, filas)


def consulta4(request):
    id_servicio = entero(request.GET.get("servicio"))
    if id_servicio:
        columnas, filas = ejecutar(SQL_USO.format(filtro="WHERE sv.id_servicio = %s"), [id_servicio])
    else:
        columnas, filas = ejecutar(SQL_USO.format(filtro=""))
    return mostrar(request, 4, columnas, filas,
                   servicios=Servicio.objects.all(),
                   servicio_elegido=id_servicio)