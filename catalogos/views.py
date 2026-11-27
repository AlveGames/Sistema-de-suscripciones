"""
Catálogos (Jorge Jaime): tablas pequeñas con las opciones que usa el sistema.

- Tipos de pago y tipos de métrica: CRUD completo (se pueden agregar nuevos).
- Estados de suscripción y tipos de operación: solo ver y editar el nombre.
  Sus ids son FIJOS: los usan las restricciones y los procedimientos de la base
  (1 = Activa, 1 = Contratación, etc.). Si se borraran o se agregaran, las
  reglas del negocio dejarían de funcionar.
"""
from django.shortcuts import render
from django.urls import reverse_lazy
from django.views.generic import CreateView, ListView, UpdateView

from categorias.views import Eliminar as EliminarMolde
from categorias.views import GuardarMixin
from core.models import EstadoSuscripcion, TipoMetrica, TipoOperacion, TipoPago

from .forms import EstadoForm, TipoMetricaForm, TipoOperacionForm, TipoPagoForm

FORMULARIO = "catalogos/formulario.html"
CONFIRMAR = "catalogos/confirmar_eliminar.html"


def index(request):
    catalogos = [
        {"titulo": "Tipos de pago", "url": "catalogos:tipopago_lista",
         "descripcion": "Formas en que pagan los clientes.", "total": TipoPago.objects.count()},
        {"titulo": "Tipos de métrica", "url": "catalogos:metrica_lista",
         "descripcion": "Qué se mide del uso de cada servicio y en qué unidad.", "total": TipoMetrica.objects.count()},
        {"titulo": "Estados de suscripción", "url": "catalogos:estado_lista",
         "descripcion": "Situación de una suscripción. Valores fijos del sistema.", "total": EstadoSuscripcion.objects.count()},
        {"titulo": "Tipos de operación", "url": "catalogos:tipooperacion_lista",
         "descripcion": "Lo que le puede pasar a una suscripción. Valores fijos del sistema.", "total": TipoOperacion.objects.count()},
    ]
    return render(request, "catalogos/index.html", {"catalogos": catalogos})


# ----------------------------------------------------------- TIPOS DE PAGO
class TipoPagoLista(ListView):
    model = TipoPago
    template_name = "catalogos/tipopago_lista.html"
    context_object_name = "registros"


class TipoPagoCrear(GuardarMixin, CreateView):
    model = TipoPago
    form_class = TipoPagoForm
    template_name = FORMULARIO
    success_url = reverse_lazy("catalogos:tipopago_lista")
    extra_context = {"titulo": "Nuevo tipo de pago", "volver": "catalogos:tipopago_lista"}


class TipoPagoEditar(GuardarMixin, UpdateView):
    model = TipoPago
    form_class = TipoPagoForm
    template_name = FORMULARIO
    success_url = reverse_lazy("catalogos:tipopago_lista")
    extra_context = {"titulo": "Editar tipo de pago", "volver": "catalogos:tipopago_lista"}


class TipoPagoEliminar(EliminarMolde):
    model = TipoPago
    template_name = CONFIRMAR
    success_url = reverse_lazy("catalogos:tipopago_lista")
    extra_context = {"volver": "catalogos:tipopago_lista"}


# ----------------------------------------------------------- TIPOS DE MÉTRICA
class MetricaLista(ListView):
    model = TipoMetrica
    template_name = "catalogos/metrica_lista.html"
    context_object_name = "registros"


class MetricaCrear(GuardarMixin, CreateView):
    model = TipoMetrica
    form_class = TipoMetricaForm
    template_name = FORMULARIO
    success_url = reverse_lazy("catalogos:metrica_lista")
    extra_context = {"titulo": "Nuevo tipo de métrica", "volver": "catalogos:metrica_lista"}


class MetricaEditar(GuardarMixin, UpdateView):
    model = TipoMetrica
    form_class = TipoMetricaForm
    template_name = FORMULARIO
    success_url = reverse_lazy("catalogos:metrica_lista")
    extra_context = {"titulo": "Editar tipo de métrica", "volver": "catalogos:metrica_lista"}


class MetricaEliminar(EliminarMolde):
    model = TipoMetrica
    template_name = CONFIRMAR
    success_url = reverse_lazy("catalogos:metrica_lista")
    extra_context = {"volver": "catalogos:metrica_lista"}


# ----------------------------------------------------------- ESTADOS (solo ver y editar)
class EstadoLista(ListView):
    model = EstadoSuscripcion
    template_name = "catalogos/estado_lista.html"
    context_object_name = "registros"


class EstadoEditar(GuardarMixin, UpdateView):
    model = EstadoSuscripcion
    form_class = EstadoForm
    template_name = FORMULARIO
    success_url = reverse_lazy("catalogos:estado_lista")
    extra_context = {"titulo": "Editar estado de suscripción", "volver": "catalogos:estado_lista"}


# ----------------------------------------------------------- TIPOS DE OPERACIÓN (solo ver y editar)
class TipoOperacionLista(ListView):
    model = TipoOperacion
    template_name = "catalogos/tipooperacion_lista.html"
    context_object_name = "registros"


class TipoOperacionEditar(GuardarMixin, UpdateView):
    model = TipoOperacion
    form_class = TipoOperacionForm
    template_name = FORMULARIO
    success_url = reverse_lazy("catalogos:tipooperacion_lista")
    extra_context = {"titulo": "Editar tipo de operación", "volver": "catalogos:tipooperacion_lista"}