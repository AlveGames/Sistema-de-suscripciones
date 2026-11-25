from django.shortcuts import render


def en_construccion(request):
    contexto = {"modulo": "Suscripciones", "responsable": "Eyser"}
    return render(request, "core/en_construccion.html", contexto)
