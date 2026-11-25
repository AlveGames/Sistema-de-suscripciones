from django.shortcuts import render


def en_construccion(request):
    contexto = {"modulo": "Clientes y pagos", "responsable": "Nevarez"}
    return render(request, "core/en_construccion.html", contexto)
