from django import forms

from core.models import Categoria  # CAMBIAR: tu modelo


class CategoriaForm(forms.ModelForm):  # CAMBIAR: nombre del formulario
    class Meta:
        model = Categoria  # CAMBIAR: tu modelo
        fields = ["nombre"]  # CAMBIAR: los campos de tu tabla (sin el id)
        # Para fechas, agrega un calendario así:
        # widgets = {"fecha_registro": forms.DateInput(attrs={"type": "date"})}