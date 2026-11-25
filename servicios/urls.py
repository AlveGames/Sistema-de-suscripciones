from django.urls import path

from . import views

app_name = "servicios"

urlpatterns = [
    path("", views.en_construccion, name="index"),
    path("modalidades/", views.en_construccion, name="modalidades"),
]
