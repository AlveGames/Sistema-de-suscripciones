from django.urls import path

from . import views

app_name = "suscripciones"

urlpatterns = [
    path("", views.Lista.as_view(), name="index"),
    path("contratar/", views.contratar, name="contratar"),
    path("<int:pk>/", views.Detalle.as_view(), name="detalle"),
    path("<int:pk>/<str:accion>/", views.operar, name="operar"),
]
