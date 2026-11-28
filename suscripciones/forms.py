from django import forms

from core.models import Cliente, Modalidad, TipoPago


class ModalidadChoice(forms.ModelChoiceField):
    def label_from_instance(self, m):
        meses = "mes" if m.duracion_servicio == 1 else "meses"
        return f"{m.servicio.nombre} · {m.nombre_plan} ($ {m.precio_base}, {m.duracion_servicio} {meses})"


class ContratarForm(forms.Form):
    cliente = forms.ModelChoiceField(
        queryset=Cliente.objects.filter(cliente_activo=True), label="Cliente"
    )
    modalidad = ModalidadChoice(
        queryset=Modalidad.objects.select_related("servicio").filter(servicio__estado="Activo"),
        label="Servicio y plan",
    )
    tipo_pago = forms.ModelChoiceField(queryset=TipoPago.objects.all(), label="Forma de pago")
    observacion = forms.CharField(label="Observación", max_length=300, required=False)


class RenovarForm(forms.Form):
    tipo_pago = forms.ModelChoiceField(queryset=TipoPago.objects.all(), label="Forma de pago")
    observacion = forms.CharField(label="Observación", max_length=300, required=False)


class ModificarForm(forms.Form):
    modalidad_nueva = ModalidadChoice(queryset=Modalidad.objects.none(), label="Nuevo plan")
    tipo_pago = forms.ModelChoiceField(queryset=TipoPago.objects.all(), label="Forma de pago")
    observacion = forms.CharField(label="Observación", max_length=300, required=False)

    def __init__(self, *args, suscripcion=None, **kwargs):
        super().__init__(*args, **kwargs)
        if suscripcion is not None:
            # Solo los otros planes del MISMO servicio
            self.fields["modalidad_nueva"].queryset = (
                Modalidad.objects.select_related("servicio")
                .filter(servicio_id=suscripcion.modalidad.servicio_id)
                .exclude(pk=suscripcion.modalidad_id)
            )


class ObservacionForm(forms.Form):
    observacion = forms.CharField(label="Observación (motivo)", max_length=300, required=False)
