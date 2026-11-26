from django.contrib import messages
from django.db import DatabaseError, IntegrityError
from django.db.models import Q
from django.shortcuts import redirect
from django.urls import reverse_lazy
from django.views.generic import CreateView, DeleteView, ListView, UpdateView

from core.models import RegistroUso
from core.utils import mensaje_bd

from .forms import RegistroUsoForm

MODELO = RegistroUso
FORMULARIO = RegistroUsoForm
CARPETA = "uso"
URL_LISTA = reverse_lazy("uso:index")


class Lista(ListView):
    model = MODELO
    template_name = f"{CARPETA}/lista.html"
    context_object_name = "registros"
    paginate_by = 15

    def get_queryset(self):
        registros = super().get_queryset().select_related(
            "suscripcion__cliente",
            "suscripcion__modalidad__servicio",
            "tipo_metrica",
        )
        buscar = self.request.GET.get("q", "").strip()
        if buscar:
            registros = registros.filter(
                Q(suscripcion__cliente__nombre__icontains=buscar)
                | Q(tipo_metrica__nombre__icontains=buscar)
                | Q(suscripcion__modalidad__nombre_plan__icontains=buscar)
            )
        return registros


class GuardarMixin:
    """Muestra el error de SQL Server en el formulario en vez de que la página se caiga."""

    def form_valid(self, form):
        try:
            respuesta = super().form_valid(form)
        except DatabaseError as error:
            form.add_error(None, mensaje_bd(error))
            return self.form_invalid(form)
        messages.success(self.request, "Registro guardado correctamente.")
        return respuesta


class Crear(GuardarMixin, CreateView):
    model = MODELO
    form_class = FORMULARIO
    template_name = f"{CARPETA}/formulario.html"
    success_url = URL_LISTA
    extra_context = {"titulo": "Nuevo registro de uso"}


class Editar(GuardarMixin, UpdateView):
    model = MODELO
    form_class = FORMULARIO
    template_name = f"{CARPETA}/formulario.html"
    success_url = URL_LISTA
    extra_context = {"titulo": "Editar registro de uso"}


class Eliminar(DeleteView):
    model = MODELO
    template_name = f"{CARPETA}/confirmar_eliminar.html"
    success_url = URL_LISTA

    def form_valid(self, form):
        try:
            self.object.delete()
        except IntegrityError:
            messages.error(self.request, "No se puede eliminar: este registro se está usando en otras tablas.")
            return redirect(self.success_url)
        except DatabaseError as error:
            messages.error(self.request, mensaje_bd(error))
            return redirect(self.success_url)
        messages.success(self.request, "Registro eliminado.")
        return redirect(self.success_url)