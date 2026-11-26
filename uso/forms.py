from django import forms

from core.models import RegistroUso


class RegistroUsoForm(forms.ModelForm):
    class Meta:
        model = RegistroUso
        fields = ["suscripcion", "tipo_metrica", "fecha_uso", "valor"]
        widgets = {
            "fecha_uso": forms.DateInput(attrs={"type": "date"}, format="%Y-%m-%d"),
        }

    def clean_valor(self):
        valor = self.cleaned_data["valor"]
        if valor < 0:
            raise forms.ValidationError("El valor no puede ser negativo.")
        return valor