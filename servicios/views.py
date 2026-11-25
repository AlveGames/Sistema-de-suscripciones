from django.shortcuts import render


def en_construccion(request):
    contexto = {"modulo": "Servicios y modalidades", "responsable": "Castañeda"}
    return render(request, "core/en_construccion.html", contexto)
