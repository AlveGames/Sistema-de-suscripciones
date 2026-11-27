from django.urls import path

from . import views

app_name = "catalogos"

urlpatterns = [
    path("", views.index, name="index"),

    path("tipos-pago/", views.TipoPagoLista.as_view(), name="tipopago_lista"),
    path("tipos-pago/nuevo/", views.TipoPagoCrear.as_view(), name="tipopago_crear"),
    path("tipos-pago/<int:pk>/editar/", views.TipoPagoEditar.as_view(), name="tipopago_editar"),
    path("tipos-pago/<int:pk>/eliminar/", views.TipoPagoEliminar.as_view(), name="tipopago_eliminar"),

    path("metricas/", views.MetricaLista.as_view(), name="metrica_lista"),
    path("metricas/nuevo/", views.MetricaCrear.as_view(), name="metrica_crear"),
    path("metricas/<int:pk>/editar/", views.MetricaEditar.as_view(), name="metrica_editar"),
    path("metricas/<int:pk>/eliminar/", views.MetricaEliminar.as_view(), name="metrica_eliminar"),

    path("estados/", views.EstadoLista.as_view(), name="estado_lista"),
    path("estados/<int:pk>/editar/", views.EstadoEditar.as_view(), name="estado_editar"),

    path("tipos-operacion/", views.TipoOperacionLista.as_view(), name="tipooperacion_lista"),
    path("tipos-operacion/<int:pk>/editar/", views.TipoOperacionEditar.as_view(), name="tipooperacion_editar"),
]