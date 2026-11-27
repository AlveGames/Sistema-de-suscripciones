"""
Servicios y modalidades (Castañeda). Usa el molde de Categorías.
Un servicio no se puede borrar si tiene modalidades, y una modalidad no se
puede borrar si tiene suscripciones: SQL Server lo impide por las FK.
"""
from django.db.models import Count, Q
from django.urls import reverse_lazy
from django.views.generic import CreateView, ListView, UpdateView

from categorias.views import Eliminar as EliminarMolde
from categorias.views import GuardarMixin
from core.models import Modalidad, Servicio

from .forms import ModalidadForm, ServicioForm

FORMULARIO = "servicios/formulario.html"
CONFIRMAR = "servicios/confirmar_eliminar.html"


# ----------------------------------------------------------- SERVICIOS
class ServicioLista(ListView):
    model = Servicio
    template_name = "servicios/lista.html"
    context_object_name = "registros"
    paginate_by = 15

    def get_queryset(self):
        registros = Servicio.objects.select_related("categoria").annotate(
            planes=Count("modalidades")
        ).order_by("nombre")
        buscar = self.request.GET.get("q", "").strip()
        if buscar:
            registros = registros.filter(
                Q(nombre__icontains=buscar) | Q(categoria__nombre__icontains=buscar)
            )
        return registros


class ServicioCrear(GuardarMixin, CreateView):
    model = Servicio
    form_class = ServicioForm
    template_name = FORMULARIO
    success_url = reverse_lazy("servicios:index")
    extra_context = {"titulo": "Nuevo servicio", "volver": "servicios:index"}


class ServicioEditar(GuardarMixin, UpdateView):
    model = Servicio
    form_class = ServicioForm
    template_name = FORMULARIO
    success_url = reverse_lazy("servicios:index")
    extra_context = {"titulo": "Editar servicio", "volver": "servicios:index"}


class ServicioEliminar(EliminarMolde):
    model = Servicio
    template_name = CONFIRMAR
    success_url = reverse_lazy("servicios:index")
    extra_context = {"volver": "servicios:index"}


# ----------------------------------------------------------- MODALIDADES
class ModalidadLista(ListView):
    model = Modalidad
    template_name = "servicios/modalidad_lista.html"
    context_object_name = "registros"
    paginate_by = 15

    def get_queryset(self):
        registros = Modalidad.objects.select_related("servicio").order_by("servicio__nombre", "nombre_plan")
        buscar = self.request.GET.get("q", "").strip()
        if buscar:
            registros = registros.filter(
                Q(nombre_plan__icontains=buscar) | Q(servicio__nombre__icontains=buscar)
            )
        return registros


class ModalidadCrear(GuardarMixin, CreateView):
    model = Modalidad
    form_class = ModalidadForm
    template_name = FORMULARIO
    success_url = reverse_lazy("servicios:modalidades")
    extra_context = {"titulo": "Nueva modalidad", "volver": "servicios:modalidades"}


class ModalidadEditar(GuardarMixin, UpdateView):
    model = Modalidad
    form_class = ModalidadForm
    template_name = FORMULARIO
    success_url = reverse_lazy("servicios:modalidades")
    extra_context = {"titulo": "Editar modalidad", "volver": "servicios:modalidades"}


class ModalidadEliminar(EliminarMolde):
    model = Modalidad
    template_name = CONFIRMAR
    success_url = reverse_lazy("servicios:modalidades")
    extra_context = {"volver": "servicios:modalidades"}
