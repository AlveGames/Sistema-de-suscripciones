from django.shortcuts import render


def en_construccion(request):
    contexto = {"modulo": "Catálogos", "responsable": "Jorge Jaime"}
    return render(request, "core/en_construccion.html", contexto)
