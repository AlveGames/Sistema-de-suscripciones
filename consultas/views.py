from django.shortcuts import render


def en_construccion(request):
    contexto = {"modulo": "Consultas", "responsable": "Joel Lino"}
    return render(request, "core/en_construccion.html", contexto)
