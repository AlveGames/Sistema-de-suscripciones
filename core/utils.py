import re


def mensaje_bd(error):
    """Saca el mensaje en español que lanza SQL Server (THROW de los procedimientos y triggers)."""
    texto = str(error)
    encontrado = re.search(r"\[SQL Server\]([^\[]+?)(?:\s*\(\d+\)|$)", texto)
    if encontrado:
        return encontrado.group(1).strip()
    return "No se pudo completar la operación en la base de datos."