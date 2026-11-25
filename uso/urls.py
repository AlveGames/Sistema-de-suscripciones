from django.urls import path

from . import views

app_name = "uso"

urlpatterns = [
    path("", views.en_construccion, name="index"),
]
