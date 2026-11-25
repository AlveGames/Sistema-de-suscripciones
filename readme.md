# Plataforma de servicios por suscripción

Componente Práctico 2 · Base de Datos (A1) · Grupo 2
Django 5.2 + SQL Server

## 1. Requisitos

- SQL Server y SSMS
- ODBC Driver 18 for SQL Server
- Python 3.11 o 3.12
- Git y VS Code

## 2. Instalación (una sola vez)

1. **Clonar el repositorio** y abrir la carpeta en VS Code.

2. **Crear la base de datos.** En SSMS ejecutar, en este orden:
   - `sql/01_estructura.sql`
   - `sql/02_procedimientos.sql`
   - `sql/03_datos.sql`

3. **Crear el entorno virtual e instalar dependencias** (en la terminal de VS Code):
   ```
   python -m venv venv
   venv\Scripts\activate
   pip install -r requirements.txt
   ```
   Si sale un error de que la ejecución de scripts está deshabilitada:
   `Set-ExecutionPolicy -Scope CurrentUser RemoteSigned` y volver a activar.

4. **Configurar la conexión.** Copiar `.env.example` como `.env` y completar:
   - `DB_HOST`: el nombre del servidor que sale al conectarse en SSMS
     (por ejemplo `localhost` o `localhost\SQLEXPRESS`).
   - `DB_USER` y `DB_PASSWORD`: vacíos si entran a SSMS con autenticación de Windows;
     si entran con `sa`, poner el usuario y la contraseña.

5. **Probar la conexión:**
   ```
   python manage.py shell -c "from core.models import Cliente; print(Cliente.objects.count())"
   ```
   Debe salir `10`.

6. **Levantar el sistema:**
   ```
   python manage.py runserver
   ```
   Abrir http://127.0.0.1:8000

> NO ejecuten `makemigrations` ni `migrate`. Las tablas las crean los scripts SQL.

## 3. Estructura y responsables

| Carpeta | Contenido | Responsable |
|---|---|---|
| `sql/` | Scripts de la base de datos | Eyser |
| `core/` | Modelos de las 12 tablas, plantilla base, menú, estilos, inicio | Eyser |
| `categorias/` | **MOLDE** para copiar | Eyser |
| `suscripciones/` | Suscripciones y operaciones | Eyser |
| `clientes/` | Clientes y pagos | Nevarez |
| `servicios/` | Servicios y modalidades | Castañeda |
| `catalogos/` | Tipos de pago, métricas, estados, tipos de operación | Jorge Jaime |
| `uso/` | Registro de uso | Rommel |
| `consultas/` | Consultas del negocio | Joel Lino |

**Reglas:**
- Cada uno trabaja **solo en su carpeta** y en **su rama**.
- No tocar `core/`, `plataforma/` ni `sql/`. Si necesitan algo ahí, avisen a Eyser.
- Los modelos se importan desde `core`: `from core.models import Cliente`.

## 4. Cómo copiar el molde

1. Copien de `categorias/` a su carpeta: `forms.py`, `views.py`, `urls.py`
   y la carpeta `templates/categorias/`.
2. Renombren la carpeta de plantillas con el nombre de su app:
   `templates/clientes/`, `templates/servicios/`, etc.
3. Busquen todas las líneas marcadas con **`CAMBIAR`** y cámbienlas por su tabla:
   modelo, formulario, campos, nombre de la app, títulos y columnas de la lista.
4. La lista principal de su módulo **debe llamarse `index`** en `urls.py`,
   porque el menú enlaza ahí. Además:
   - En `clientes`, la lista de pagos se llama `pagos` y sus rutas llevan "pago" en el nombre
     (`pago_editar`, `pago_eliminar`).
   - En `servicios`, la lista de modalidades se llama `modalidades` y sus rutas llevan
     "modalidad" en el nombre (`modalidad_crear`, `modalidad_editar`, `modalidad_eliminar`).
5. Si su módulo tiene dos tablas, dupliquen las clases en el mismo `views.py`
   con otro nombre (por ejemplo `ModalidadLista`, `ModalidadCrear`) y sus plantillas.
6. Prueben: crear, ver, editar, eliminar y un registro duplicado.

## 5. Errores comunes

| Error | Solución |
|---|---|
| `Data source name not found` / driver | Instalar ODBC Driver 18, o en `.env` poner `DB_DRIVER=ODBC Driver 17 for SQL Server` |
| `Login failed` | Revisar `DB_USER` y `DB_PASSWORD` en `.env` |
| `Cannot open database "PlataformaSuscripciones"` | Falta ejecutar los scripts de `sql/` |
| `No module named ...` | Activar el entorno (`venv\Scripts\activate`) y `pip install -r requirements.txt` |
| `SQL Server v17 is not supported` | Tener `mssql-django==1.7.4` (está en `requirements.txt`) |