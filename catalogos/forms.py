from django import forms

from core.models import EstadoSuscripcion, TipoMetrica, TipoOperacion, TipoPago


class TipoPagoForm(forms.ModelForm):
    class Meta:
        model = TipoPago
        fields = ["nombre_tipo_metodo"]


class TipoMetricaForm(forms.ModelForm):
    class Meta:
        model = TipoMetrica
        fields = ["nombre", "unidad"]


class EstadoForm(forms.ModelForm):
    class Meta:
        model = EstadoSuscripcion
        fields = ["nombre"]


class TipoOperacionForm(forms.ModelForm):
    class Meta:
        model = TipoOperacion
        fields = ["nombre_operacion", "descripcion"]