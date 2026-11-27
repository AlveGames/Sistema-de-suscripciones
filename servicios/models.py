from django import forms
from core.models import Servicio, Modalidad


class ServicioForm(forms.ModelForm):
    class Meta:
        model = Servicio
        fields = ["categoria", "nombre", "descripcion", "estado"]


class ModalidadForm(forms.ModelForm):
    class Meta:
        model = Modalidad
        fields = ["servicio", "nombre_plan", "duracion_servicio", "precio_base"]

    def clean_duracion_servicio(self):
        d = self.cleaned_data["duracion_servicio"]
        if d < 1:
            raise forms.ValidationError("La duración debe ser de al menos 1 mes.")
        return d

    def clean_precio_base(self):
        p = self.cleaned_data["precio_base"]
        if p < 0:
            raise forms.ValidationError("El precio no puede ser negativo.")
        return p