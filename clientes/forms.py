from django import forms
from core.models import Cliente, Pago

class ClienteForm(forms.ModelForm):
    class Meta:
        model = Cliente
        fields = ["nombre", "documento", "correo", "telefono", "fecha_registro", "cliente_activo", "tipo_cliente"]
        widgets = {
            "fecha_registro": forms.DateInput(attrs={"type": "date"}),
        }

    def clean_documento(self):
        documento = self.cleaned_data.get("documento")
        query = Cliente.objects.filter(documento=documento)
        if self.instance.pk:
            query = query.exclude(pk=self.instance.pk)
        if query.exists():
            raise forms.ValidationError("El documento ya está registrado en otro cliente.")
        return documento

class PagoForm(forms.ModelForm):
    class Meta:
        model = Pago
        fields = ["cliente", "operacion", "tipo_pago", "fecha", "monto"]
        widgets = {
            "fecha": forms.DateInput(attrs={"type": "date"}),
        }