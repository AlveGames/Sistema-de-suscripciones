from datetime import date

from django.db.models import Sum
from django.shortcuts import render

from .models import ESTADO_ACTIVA, Cliente, OperacionSuscripcion, Pago, Servicio, Suscripcion


def inicio(request):
    hoy = date.today()
    ingresos_mes = (
        Pago.objects.filter(fecha_pago__year=hoy.year, fecha_pago__month=hoy.month)
        .aggregate(total=Sum("monto"))["total"] or 0
    )
    contexto = {
        "clientes_activos": Cliente.objects.filter(cliente_activo=True).count(),
        "suscripciones_activas": Suscripcion.objects.filter(estado_id=ESTADO_ACTIVA).count(),
        "servicios_activos": Servicio.objects.filter(estado="Activo").count(),
        "ingresos_mes": ingresos_mes,
        "ultimas_operaciones": OperacionSuscripcion.objects.select_related(
            "suscripcion__cliente", "tipo_operacion", "modalidad_nueva__servicio"
        ).order_by("-fecha_operacion", "-id_operacion_suscripcion")[:8],
    }
    return render(request, "core/inicio.html", contexto)