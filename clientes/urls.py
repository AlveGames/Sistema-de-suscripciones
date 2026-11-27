from django.urls import path
from . import views

app_name = "clientes"

urlpatterns = [
    # Clientes
    path("", views.ClienteLista.as_view(), name="index"),
    path("nuevo/", views.ClienteCrear.as_view(), name="crear"),
    path("<int:pk>/editar/", views.ClienteEditar.as_view(), name="editar"),
    path("<int:pk>/eliminar/", views.ClienteEliminar.as_view(), name="eliminar"),
    
    # Pagos
    path("pagos/", views.PagoLista.as_view(), name="pagos"),
    path("pago/<int:pk>/editar/", views.PagoEditar.as_view(), name="pago_editar"),
    path("pago/<int:pk>/eliminar/", views.PagoEliminar.as_view(), name="pago_eliminar"),
]