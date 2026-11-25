"""
Modelos de las 12 tablas. managed = False: las tablas ya existen
(las crean los scripts de sql/). Django solo lee y escribe en ellas.
Nadie modifica este archivo sin avisar a Eyser.
"""
from datetime import date

from django.db import models

# Ids fijos cargados en sql/01_estructura.sql
ESTADO_ACTIVA, ESTADO_SUSPENDIDA, ESTADO_CANCELADA = 1, 2, 3


# ---------------- PARAMÉTRICAS ----------------
class Categoria(models.Model):
    id_categoria = models.AutoField(primary_key=True)
    nombre = models.CharField(max_length=80, unique=True)

    class Meta:
        managed = False
        db_table = "categoria"
        ordering = ["nombre"]

    def __str__(self):
        return self.nombre


class EstadoSuscripcion(models.Model):
    id_estado_suscripcion = models.AutoField(primary_key=True)
    nombre = models.CharField(max_length=30, unique=True)

    class Meta:
        managed = False
        db_table = "estado_suscripcion"
        ordering = ["id_estado_suscripcion"]

    def __str__(self):
        return self.nombre


class TipoOperacion(models.Model):
    id_tipo_operacion = models.AutoField(primary_key=True)
    nombre_operacion = models.CharField(max_length=30, unique=True)
    descripcion = models.CharField(max_length=200, null=True, blank=True)

    class Meta:
        managed = False
        db_table = "tipo_operacion"
        ordering = ["id_tipo_operacion"]

    def __str__(self):
        return self.nombre_operacion


class TipoPago(models.Model):
    id_tipo_pago = models.AutoField(primary_key=True)
    nombre_tipo_metodo = models.CharField("método de pago", max_length=50, unique=True)

    class Meta:
        managed = False
        db_table = "tipo_pago"
        ordering = ["nombre_tipo_metodo"]

    def __str__(self):
        return self.nombre_tipo_metodo


class TipoMetrica(models.Model):
    id_tipo_metrica = models.AutoField(primary_key=True)
    nombre = models.CharField(max_length=50, unique=True)
    unidad = models.CharField(max_length=20)

    class Meta:
        managed = False
        db_table = "tipo_metrica"
        ordering = ["nombre"]

    def __str__(self):
        return f"{self.nombre} ({self.unidad})"


# ---------------- MAESTRAS ----------------
class Cliente(models.Model):
    TIPOS = [("Persona", "Persona"), ("Organización", "Organización")]

    id_cliente = models.AutoField(primary_key=True)
    nombre = models.CharField(max_length=150)
    documento = models.CharField("cédula o RUC", max_length=13, unique=True)
    correo = models.EmailField(max_length=120)
    telefono = models.CharField("teléfono", max_length=15, null=True, blank=True)
    fecha_registro = models.DateField("fecha de registro", default=date.today)
    cliente_activo = models.BooleanField("activo", default=True)
    tipo_cliente = models.CharField("tipo de cliente", max_length=15, choices=TIPOS)

    class Meta:
        managed = False
        db_table = "cliente"
        ordering = ["nombre"]

    def __str__(self):
        return self.nombre


class Servicio(models.Model):
    ESTADOS = [("Activo", "Activo"), ("Inactivo", "Inactivo")]

    id_servicio = models.AutoField(primary_key=True)
    categoria = models.ForeignKey(Categoria, models.DO_NOTHING,
                                  db_column="id_categoria", related_name="servicios")
    nombre = models.CharField(max_length=100)
    descripcion = models.CharField("descripción", max_length=300, null=True, blank=True)
    estado = models.CharField(max_length=10, choices=ESTADOS, default="Activo")

    class Meta:
        managed = False
        db_table = "servicio"
        ordering = ["nombre"]

    def __str__(self):
        return self.nombre


class Modalidad(models.Model):
    id_modalidad = models.AutoField(primary_key=True)
    servicio = models.ForeignKey(Servicio, models.DO_NOTHING,
                                 db_column="id_servicio", related_name="modalidades")
    nombre_plan = models.CharField("nombre del plan", max_length=60)
    duracion_servicio = models.PositiveIntegerField("duración (meses)")
    precio_base = models.DecimalField("precio base", max_digits=10, decimal_places=2)

    class Meta:
        managed = False
        db_table = "modalidad"
        ordering = ["servicio__nombre", "nombre_plan"]
        constraints = [
            models.UniqueConstraint(
                fields=["servicio", "nombre_plan"],
                name="UQ_modalidad_servicio_plan",
                violation_error_message="Este servicio ya tiene un plan con ese nombre.",
            )
        ]

    def __str__(self):
        return f"{self.servicio.nombre} - {self.nombre_plan}"


# ---------------- TRANSACCIONALES ----------------
class Suscripcion(models.Model):
    id_suscripcion = models.AutoField(primary_key=True)
    cliente = models.ForeignKey(Cliente, models.DO_NOTHING,
                                db_column="id_cliente", related_name="suscripciones")
    modalidad = models.ForeignKey(Modalidad, models.DO_NOTHING,
                                  db_column="id_modalidad", related_name="suscripciones")
    estado = models.ForeignKey(EstadoSuscripcion, models.DO_NOTHING,
                               db_column="id_estado_suscripcion", related_name="suscripciones")
    fecha_inicio = models.DateField("fecha de inicio")
    fecha_fin = models.DateField("fecha de fin")

    class Meta:
        managed = False
        db_table = "suscripcion"
        ordering = ["-id_suscripcion"]

    def __str__(self):
        return f"#{self.id_suscripcion} {self.cliente.nombre} - {self.modalidad}"


class OperacionSuscripcion(models.Model):
    id_operacion_suscripcion = models.AutoField(primary_key=True)
    suscripcion = models.ForeignKey(Suscripcion, models.DO_NOTHING,
                                    db_column="id_suscripcion", related_name="operaciones")
    tipo_operacion = models.ForeignKey(TipoOperacion, models.DO_NOTHING,
                                       db_column="id_tipo_operacion", related_name="operaciones")
    modalidad_anterior = models.ForeignKey(Modalidad, models.DO_NOTHING,
                                           db_column="id_modalidad_anterior",
                                           related_name="operaciones_como_anterior",
                                           null=True, blank=True)
    modalidad_nueva = models.ForeignKey(Modalidad, models.DO_NOTHING,
                                        db_column="id_modalidad_nueva",
                                        related_name="operaciones_como_nueva")
    precio_aplicado = models.DecimalField(max_digits=10, decimal_places=2, null=True, blank=True)
    fecha_inicio_periodo = models.DateField(null=True, blank=True)
    fecha_fin_periodo = models.DateField(null=True, blank=True)
    fecha_operacion = models.DateTimeField()
    observacion = models.CharField("observación", max_length=300, null=True, blank=True)

    class Meta:
        managed = False
        db_table = "operacion_suscripcion"
        ordering = ["fecha_operacion", "id_operacion_suscripcion"]

    def __str__(self):
        return f"{self.tipo_operacion} - {self.fecha_operacion:%Y-%m-%d}"


class Pago(models.Model):
    id_pago = models.AutoField(primary_key=True)
    operacion = models.ForeignKey(OperacionSuscripcion, models.DO_NOTHING,
                                  db_column="id_operacion_suscripcion", related_name="pagos")
    tipo_pago = models.ForeignKey(TipoPago, models.DO_NOTHING,
                                  db_column="id_tipo_pago", related_name="pagos")
    fecha_pago = models.DateTimeField("fecha de pago")
    monto = models.DecimalField(max_digits=10, decimal_places=2)

    class Meta:
        managed = False
        db_table = "pago"
        ordering = ["-fecha_pago"]

    def __str__(self):
        return f"Pago #{self.id_pago} - {self.monto}"


class RegistroUso(models.Model):
    id_uso = models.AutoField(primary_key=True)
    suscripcion = models.ForeignKey(Suscripcion, models.DO_NOTHING,
                                    db_column="id_suscripcion", related_name="usos")
    tipo_metrica = models.ForeignKey(TipoMetrica, models.DO_NOTHING,
                                     db_column="id_tipo_metrica", related_name="usos")
    fecha_uso = models.DateField("fecha de uso")
    valor = models.DecimalField(max_digits=12, decimal_places=2)

    class Meta:
        managed = False
        db_table = "registro_uso"
        ordering = ["-fecha_uso"]

    def __str__(self):
        return f"{self.tipo_metrica.nombre}: {self.valor}"