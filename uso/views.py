from django.shortcuts import render


def en_construccion(request):
    contexto = {"modulo": "Registro de uso", "responsable": "Rommel"}
    return render(request, "core/en_construccion.html", contexto)
