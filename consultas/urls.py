from django.urls import path

from . import views

app_name = "consultas"

urlpatterns = [
    path("", views.en_construccion, name="index"),
]
