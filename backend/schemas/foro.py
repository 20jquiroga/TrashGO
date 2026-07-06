from datetime import datetime

from pydantic import BaseModel, ConfigDict


# --- Schemas de ENTRADA (datos que manda el cliente) ---

class ForoCrear(BaseModel):
    """Datos que el usuario envía para crear un tema en el foro."""
    titulo: str
    descripcion: str


class MensajeCrear(BaseModel):
    """Datos que el usuario envía para escribir un mensaje en un foro."""
    contenido: str


# --- Schemas de SALIDA (datos que devuelve la API) ---

class ForoRespuesta(BaseModel):
    """Datos de un tema del foro que la API devuelve al cliente."""
    id: int
    titulo: str
    descripcion: str
    autor_nombre: str
    created_at: datetime

    # from_attributes=True permite construir este schema desde un objeto SQLAlchemy
    model_config = ConfigDict(from_attributes=True)


class MensajeRespuesta(BaseModel):
    """Datos de un mensaje del foro que la API devuelve al cliente."""
    id: int
    contenido: str
    autor_nombre: str
    created_at: datetime

    # from_attributes=True permite construir este schema desde un objeto SQLAlchemy
    model_config = ConfigDict(from_attributes=True)
