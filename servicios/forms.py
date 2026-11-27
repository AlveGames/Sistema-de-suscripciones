from django import forms

from core.models import Modalidad, Servicio


class ServicioForm(forms.ModelForm):
    class Meta:
        model = Servicio
        fields = ["categoria", "nombre", "descripcion", "estado"]


class ModalidadForm(forms.ModelForm):
    class Meta:
        model = Modalidad
        fields = ["servicio", "nombre_plan", "duracion_servicio", "precio_base"]

    def clean_duracion_servicio(self):
        duracion = self.cleaned_data["duracion_servicio"]
        if duracion < 1:
            raise forms.ValidationError("La duración debe ser de al menos 1 mes.")
        return duracion

    def clean_precio_base(self):
        precio = self.cleaned_data["precio_base"]
        if precio < 0:
            raise forms.ValidationError("El precio no puede ser negativo.")
        return precio
