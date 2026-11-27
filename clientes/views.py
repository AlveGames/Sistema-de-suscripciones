from django.contrib import messages
from django.db import DatabaseError, IntegrityError
from django.shortcuts import redirect
from django.urls import reverse_lazy
from django.views.generic import CreateView, DeleteView, ListView, UpdateView

from core.models import Cliente, Pago
from core.utils import mensaje_bd
from .forms import ClienteForm, PagoForm

# ==========================================
# CRUD DE CLIENTES
# ==========================================
class ClienteLista(ListView):
    model = Cliente
    template_name = "clientes/lista.html"
    context_object_name = "registros"
    paginate_by = 15

    def get_queryset(self):
        registros = super().get_queryset()
        buscar = self.request.GET.get("q", "").strip()
        if buscar:
            registros = registros.filter(nombre__icontains=buscar)
        return registros

class ClienteGuardarMixin:
    def form_valid(self, form):
        try:
            respuesta = super().form_valid(form)
        except DatabaseError as error:
            form.add_error(None, mensaje_bd(error))
            return self.form_invalid(form)
        messages.success(self.request, "Cliente guardado correctamente.")
        return respuesta

class ClienteCrear(ClienteGuardarMixin, CreateView):
    model = Cliente
    form_class = ClienteForm
    template_name = "clientes/formulario.html"
    success_url = reverse_lazy("clientes:index")
    extra_context = {"titulo": "Nuevo Cliente"}

class ClienteEditar(ClienteGuardarMixin, UpdateView):
    model = Cliente
    form_class = ClienteForm
    template_name = "clientes/formulario.html"
    success_url = reverse_lazy("clientes:index")
    extra_context = {"titulo": "Editar Cliente"}

class ClienteEliminar(DeleteView):
    model = Cliente
    template_name = "clientes/confirmar_eliminar.html"
    success_url = reverse_lazy("clientes:index")

    def form_valid(self, form):
        try:
            self.object.delete()
        except IntegrityError:
            messages.error(self.request, "No se puede eliminar: el cliente tiene suscripciones.")
            return redirect(self.success_url)
        except DatabaseError as error:
            messages.error(self.request, mensaje_bd(error))
            return redirect(self.success_url)
        messages.success(self.request, "Cliente eliminado.")
        return redirect(self.success_url)

# ==========================================
# CRUD DE PAGOS
# ==========================================
class PagoLista(ListView):
    model = Pago
    template_name = "clientes/pagos.html" 
    context_object_name = "pagos"
    paginate_by = 15

    # <--- ESTO ES LO NUEVO QUE PUSO EYSER
    def get_queryset(self):
        return super().get_queryset().select_related(
            "operacion__suscripcion__cliente", "operacion__tipo_operacion", "tipo_pago"
        )

class PagoGuardarMixin:
    def form_valid(self, form):
        try:
            respuesta = super().form_valid(form)
        except DatabaseError as error:
            form.add_error(None, mensaje_bd(error))
            return self.form_invalid(form)
        messages.success(self.request, "Pago actualizado correctamente.")
        return respuesta

class PagoEditar(PagoGuardarMixin, UpdateView):
    model = Pago
    form_class = PagoForm
    template_name = "clientes/formulario.html"
    success_url = reverse_lazy("clientes:pagos")
    extra_context = {"titulo": "Editar Pago"}

class PagoEliminar(DeleteView):
    model = Pago
    template_name = "clientes/confirmar_eliminar.html"
    success_url = reverse_lazy("clientes:pagos")

    def form_valid(self, form):
        try:
            self.object.delete()
        except IntegrityError:
            messages.error(self.request, "No se puede eliminar el pago.")
            return redirect(self.success_url)
        except DatabaseError as error:
            messages.error(self.request, mensaje_bd(error))
            return redirect(self.success_url)
        messages.success(self.request, "Pago eliminado.")
        return redirect(self.success_url)