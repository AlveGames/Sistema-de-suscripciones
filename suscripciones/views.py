"""
Suscripciones y operaciones (Eyser).

Las operaciones NO escriben directo en las tablas: llaman a los procedimientos
almacenados de sql/02_procedimientos.sql. Cada procedimiento valida las reglas,
registra la operación en el historial, registra el pago si la operación cobra
y actualiza la suscripción, todo en una sola transacción.
"""
from django.contrib import messages
from django.db import DatabaseError, connection
from django.db.models import Prefetch, Q
from django.shortcuts import get_object_or_404, redirect, render
from django.views.generic import DetailView, ListView

from core.models import (
    ESTADO_ACTIVA,
    ESTADO_SUSPENDIDA,
    EstadoSuscripcion,
    OperacionSuscripcion,
    Pago,
    Suscripcion,
)
from core.utils import mensaje_bd

from .forms import ContratarForm, ModificarForm, ObservacionForm, RenovarForm


def ejecutar_procedimiento(nombre, parametros, devolver_id=False):
    """Ejecuta un procedimiento almacenado con parámetros con nombre.
    Si devolver_id es True, devuelve el @id_suscripcion de salida."""
    asignaciones = ", ".join(f"@{clave} = %s" for clave in parametros)
    valores = list(parametros.values())
    if devolver_id:
        sql = (f"SET NOCOUNT ON; DECLARE @id INT; "
               f"EXEC {nombre} {asignaciones}, @id_suscripcion = @id OUTPUT; SELECT @id;")
    else:
        sql = f"SET NOCOUNT ON; EXEC {nombre} {asignaciones};"
    with connection.cursor() as cursor:
        cursor.execute(sql, valores)
        if devolver_id:
            return cursor.fetchone()[0]
    return None


# ----------------------------------------------------------- LISTA Y DETALLE
class Lista(ListView):
    model = Suscripcion
    template_name = "suscripciones/lista.html"
    context_object_name = "registros"
    paginate_by = 15

    def get_queryset(self):
        registros = Suscripcion.objects.select_related(
            "cliente", "modalidad__servicio", "estado"
        ).order_by("-id_suscripcion")
        estado = self.request.GET.get("estado", "")
        if estado.isdigit():
            registros = registros.filter(estado_id=int(estado))
        buscar = self.request.GET.get("q", "").strip()
        if buscar:
            registros = registros.filter(
                Q(cliente__nombre__icontains=buscar) | Q(cliente__documento__icontains=buscar)
            )
        return registros

    def get_context_data(self, **kwargs):
        contexto = super().get_context_data(**kwargs)
        contexto["estados"] = EstadoSuscripcion.objects.all()
        contexto["estado_elegido"] = self.request.GET.get("estado", "")
        return contexto


class Detalle(DetailView):
    model = Suscripcion
    template_name = "suscripciones/detalle.html"
    context_object_name = "s"

    def get_queryset(self):
        return Suscripcion.objects.select_related("cliente", "modalidad__servicio", "estado")

    def get_context_data(self, **kwargs):
        contexto = super().get_context_data(**kwargs)
        s = self.object
        contexto["operaciones"] = (
            OperacionSuscripcion.objects.filter(suscripcion=s)
            .select_related("tipo_operacion", "modalidad_anterior", "modalidad_nueva")
            .prefetch_related(Prefetch("pagos", queryset=Pago.objects.select_related("tipo_pago")))
            .order_by("fecha_operacion", "id_operacion_suscripcion")
        )
        contexto["total_pagado"] = sum(
            p.monto for p in Pago.objects.filter(operacion__suscripcion=s)
        )
        contexto["acciones"] = acciones_permitidas(s)
        return contexto


# ----------------------------------------------------------- CONTRATAR
def contratar(request):
    form = ContratarForm(request.POST if request.method == "POST" else None)
    if request.method == "POST" and form.is_valid():
        datos = form.cleaned_data
        try:
            nuevo_id = ejecutar_procedimiento("usp_contratar_suscripcion", {
                "id_cliente": datos["cliente"].pk,
                "id_modalidad": datos["modalidad"].pk,
                "id_tipo_pago": datos["tipo_pago"].pk,
                "observacion": datos["observacion"] or None,
            }, devolver_id=True)
        except DatabaseError as error:
            form.add_error(None, mensaje_bd(error))
        else:
            messages.success(request, "Suscripción contratada y primer pago registrado.")
            return redirect("suscripciones:detalle", pk=nuevo_id)
    return render(request, "suscripciones/formulario.html", {
        "titulo": "Contratar suscripción",
        "form": form,
        "boton": "Contratar",
    })


# ----------------------------------------------------------- OPERACIONES
OPERACIONES = {
    "renovar": {
        "titulo": "Renovar suscripción", "boton": "Renovar", "form": RenovarForm,
        "procedimiento": "usp_renovar_suscripcion", "estados": [ESTADO_ACTIVA],
        "ayuda": "El nuevo periodo empieza donde termina el actual y se cobra el precio vigente del plan.",
    },
    "modificar": {
        "titulo": "Cambiar de plan", "boton": "Cambiar plan", "form": ModificarForm,
        "procedimiento": "usp_modificar_suscripcion", "estados": [ESTADO_ACTIVA],
        "ayuda": "Solo se puede cambiar a otro plan del mismo servicio. El nuevo periodo empieza hoy y se cobra el nuevo plan.",
    },
    "suspender": {
        "titulo": "Suspender suscripción", "boton": "Suspender", "form": ObservacionForm,
        "procedimiento": "usp_suspender_suscripcion", "estados": [ESTADO_ACTIVA],
        "ayuda": "La suscripción queda pausada. No genera cobro.",
    },
    "reactivar": {
        "titulo": "Reactivar suscripción", "boton": "Reactivar", "form": ObservacionForm,
        "procedimiento": "usp_reactivar_suscripcion", "estados": [ESTADO_SUSPENDIDA],
        "ayuda": "La suscripción vuelve a estar activa. No genera cobro.",
    },
    "cancelar": {
        "titulo": "Cancelar suscripción", "boton": "Cancelar suscripción", "form": ObservacionForm,
        "procedimiento": "usp_cancelar_suscripcion", "estados": [ESTADO_ACTIVA, ESTADO_SUSPENDIDA],
        "ayuda": "La suscripción termina y queda en el historial. No genera cobro.",
    },
}


def acciones_permitidas(suscripcion):
    """Qué botones se muestran según el estado de la suscripción."""
    return [clave for clave, op in OPERACIONES.items() if suscripcion.estado_id in op["estados"]]


def operar(request, pk, accion):
    if accion not in OPERACIONES:
        return redirect("suscripciones:detalle", pk=pk)
    op = OPERACIONES[accion]
    s = get_object_or_404(Suscripcion.objects.select_related("cliente", "modalidad__servicio", "estado"), pk=pk)
    if s.estado_id not in op["estados"]:
        messages.error(request, f"No se puede {accion} una suscripción en estado {s.estado}.")
        return redirect("suscripciones:detalle", pk=pk)

    extra = {"suscripcion": s} if accion == "modificar" else {}
    form = op["form"](request.POST if request.method == "POST" else None, **extra)
    if request.method == "POST" and form.is_valid():
        datos = form.cleaned_data
        parametros = {"id_suscripcion": s.pk}
        if accion == "modificar":
            parametros["id_modalidad_nueva"] = datos["modalidad_nueva"].pk
        if "tipo_pago" in datos:
            parametros["id_tipo_pago"] = datos["tipo_pago"].pk
        parametros["observacion"] = datos["observacion"] or None
        try:
            ejecutar_procedimiento(op["procedimiento"], parametros)
        except DatabaseError as error:
            form.add_error(None, mensaje_bd(error))
        else:
            messages.success(request, f"Operación registrada: {op['titulo'].lower()}.")
            return redirect("suscripciones:detalle", pk=pk)

    return render(request, "suscripciones/formulario.html", {
        "titulo": op["titulo"],
        "form": form,
        "boton": op["boton"],
        "ayuda": op["ayuda"],
        "s": s,
        "peligro": accion == "cancelar",
    })
