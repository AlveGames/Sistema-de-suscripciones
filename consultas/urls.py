from django.urls import path

from . import views

app_name = "consultas"

urlpatterns = [
path("", views.index, name="index"),
path("1/", views.consulta1, name="consulta1"),
path("2/", views.consulta2, name="consulta2"),
path("3/", views.consulta3, name="consulta3"),
path("4/", views.consulta4, name="consulta4"),
]