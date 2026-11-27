from django.contrib import messages
from django.db import IntegrityError
from django.shortcuts import redirect
from django.urls import reverse_lazy
from django.views.generic import ListView, CreateView, UpdateView, DeleteView

from core.models import Servicio, Modalidad
from .forms import ServicioForm, ModalidadForm


class EliminarSeguro:
    """Muestra un mensaje si la fila está referenciada por otras tablas."""
    mensaje_error = "No se puede eliminar: tiene registros relacionados."

    def form_valid(self, form):
        try:
            return super().form_valid(form)
        except IntegrityError:
            messages.error(self.request, self.mensaje_error)
            return redirect(self.success_url)


# ---------------- Servicios ----------------
class ServicioLista(ListView):
    model = Servicio
    template_name = "servicios/lista.html"
    context_object_name = "objetos"

    def get_queryset(self):
        return Servicio.objects.select_related("categoria")


class ServicioCrear(CreateView):
    model = Servicio
    form_class = ServicioForm
    template_name = "servicios/form.html"
    success_url = reverse_lazy("servicios:index")


class ServicioEditar(UpdateView):
    model = Servicio
    form_class = ServicioForm
    template_name = "servicios/form.html"
    success_url = reverse_lazy("servicios:index")


class ServicioEliminar(EliminarSeguro, DeleteView):
    model = Servicio
    template_name = "servicios/confirmar_eliminar.html"
    success_url = reverse_lazy("servicios:index")
    mensaje_error = "No se puede eliminar el servicio: tiene modalidades asociadas."


# ---------------- Modalidades ----------------
class ModalidadLista(ListView):
    model = Modalidad
    template_name = "servicios/modalidad_lista.html"
    context_object_name = "objetos"

    def get_queryset(self):
        return Modalidad.objects.select_related("servicio")


class ModalidadCrear(CreateView):
    model = Modalidad
    form_class = ModalidadForm
    template_name = "servicios/modalidad_form.html"
    success_url = reverse_lazy("servicios:modalidades")


class ModalidadEditar(UpdateView):
    model = Modalidad
    form_class = ModalidadForm
    template_name = "servicios/modalidad_form.html"
    success_url = reverse_lazy("servicios:modalidades")


class ModalidadEliminar(EliminarSeguro, DeleteView):
    model = Modalidad
    template_name = "servicios/modalidad_confirmar_eliminar.html"
    success_url = reverse_lazy("servicios:modalidades")
    mensaje_error = "No se puede eliminar la modalidad: tiene suscripciones asociadas."