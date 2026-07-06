from datetime import datetime

from pydantic import BaseModel, ConfigDict


# --- Schema de ENTRADA (datos que manda el cliente para crear un punto) ---

class PuntoComunitarioCrear(BaseModel):
    """Datos que el usuario envía para crear un punto de recolección."""
    nombre: str
    descripcion: str = ""          # opcional, por defecto vacío
    latitud: float
    longitud: float
    sector: str = ""               # opcional
    dias_recoleccion: str = ""     # opcional
    horario: str = ""              # opcional
    tipo_residuo: str = ""         # tipo de basura que acepta (ej: "Plástico")


# --- Schema de SALIDA (datos que devuelve la API) ---

class PuntoComunitarioRespuesta(BaseModel):
    """Datos de un punto de recolección que la API devuelve al cliente.
    Incluye tanto los puntos oficiales (es_oficial=True) como los que crean
    los usuarios (es_oficial=False)."""
    id: int
    nombre: str
    descripcion: str
    latitud: float
    longitud: float
    sector: str
    dias_recoleccion: str
    horario: str
    tipo_residuo: str
    autor_nombre: str
    es_oficial: bool
    created_at: datetime

    # from_attributes=True permite construir este schema desde un objeto SQLAlchemy
    model_config = ConfigDict(from_attributes=True)
