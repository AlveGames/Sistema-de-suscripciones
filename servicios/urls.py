from django.urls import path

from . import views

app_name = "servicios"

urlpatterns = [
    path("", views.ServicioLista.as_view(), name="index"),
    path("nuevo/", views.ServicioCrear.as_view(), name="crear"),
    path("<int:pk>/editar/", views.ServicioEditar.as_view(), name="editar"),
    path("<int:pk>/eliminar/", views.ServicioEliminar.as_view(), name="eliminar"),

    path("modalidades/", views.ModalidadLista.as_view(), name="modalidades"),
    path("modalidades/nuevo/", views.ModalidadCrear.as_view(), name="modalidad_crear"),
    path("modalidades/<int:pk>/editar/", views.ModalidadEditar.as_view(), name="modalidad_editar"),
    path("modalidades/<int:pk>/eliminar/", views.ModalidadEliminar.as_view(), name="modalidad_eliminar"),
]
