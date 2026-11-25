from django.urls import path

from . import views

app_name = "categorias"  # CAMBIAR: nombre de tu app

urlpatterns = [
    path("", views.Lista.as_view(), name="index"),
    path("nuevo/", views.Crear.as_view(), name="crear"),
    path("<int:pk>/editar/", views.Editar.as_view(), name="editar"),
    path("<int:pk>/eliminar/", views.Eliminar.as_view(), name="eliminar"),
]