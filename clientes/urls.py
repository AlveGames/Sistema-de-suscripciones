from django.urls import path

from . import views

app_name = "clientes"

urlpatterns = [
    path("", views.en_construccion, name="index"),
    path("pagos/", views.en_construccion, name="pagos"),
]
