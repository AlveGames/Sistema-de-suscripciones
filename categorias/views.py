"""
MOLDE DE CRUD. Para copiarlo a tu tabla cambia las líneas marcadas con CAMBIAR.
"""
from django.contrib import messages
from django.db import DatabaseError, IntegrityError
from django.shortcuts import redirect
from django.urls import reverse_lazy
from django.views.generic import CreateView, DeleteView, ListView, UpdateView

from core.models import Categoria  # CAMBIAR: tu modelo
from core.utils import mensaje_bd

from .forms import CategoriaForm  # CAMBIAR: tu formulario

MODELO = Categoria  # CAMBIAR
FORMULARIO = CategoriaForm  # CAMBIAR
CARPETA = "categorias"  # CAMBIAR: nombre de tu app (carpeta de plantillas)
URL_LISTA = reverse_lazy("categorias:index")  # CAMBIAR: "tuapp:index"


class Lista(ListView):
    model = MODELO
    template_name = f"{CARPETA}/lista.html"
    context_object_name = "registros"
    paginate_by = 15

    def get_queryset(self):
        registros = super().get_queryset()
        buscar = self.request.GET.get("q", "").strip()
        if buscar:
            registros = registros.filter(nombre__icontains=buscar)  # CAMBIAR: campo de búsqueda
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
    extra_context = {"titulo": "Nueva categoría"}  # CAMBIAR


class Editar(GuardarMixin, UpdateView):
    model = MODELO
    form_class = FORMULARIO
    template_name = f"{CARPETA}/formulario.html"
    success_url = URL_LISTA
    extra_context = {"titulo": "Editar categoría"}  # CAMBIAR


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