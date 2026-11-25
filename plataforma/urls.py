from django.urls import include, path

urlpatterns = [
    path("", include("core.urls")),
    path("categorias/", include("categorias.urls")),
    path("clientes/", include("clientes.urls")),
    path("servicios/", include("servicios.urls")),
    path("catalogos/", include("catalogos.urls")),
    path("uso/", include("uso.urls")),
    path("suscripciones/", include("suscripciones.urls")),
    path("consultas/", include("consultas.urls")),
]