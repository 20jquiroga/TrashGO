from datetime import datetime

from pydantic import BaseModel, ConfigDict, EmailStr


# --- Schemas de ENTRADA (datos que manda el cliente) ---

class UsuarioRegistro(BaseModel):
    """Datos que el usuario envía para crear una cuenta."""
    nombre: str
    email: EmailStr          # Pydantic valida automáticamente que sea un email real
    password: str


class UsuarioLogin(BaseModel):
    """Datos que el usuario envía para iniciar sesión."""
    email: EmailStr
    password: str


# --- Schemas de SALIDA (datos que devuelve la API) ---

class UsuarioRespuesta(BaseModel):
    """Datos del usuario que la API puede mostrar de forma segura.
    Nunca incluye password_hash."""
    id: int
    nombre: str
    email: str
    created_at: datetime

    # from_attributes=True permite construir este schema desde un objeto SQLAlchemy
    # (antes se llamaba orm_mode=True en Pydantic v1)
    model_config = ConfigDict(from_attributes=True)


class TokenRespuesta(BaseModel):
    """Respuesta al registrarse o iniciar sesión: incluye el token JWT y los datos del usuario."""
    access_token: str
    token_type: str = "bearer"   # El tipo estándar para tokens JWT
    usuario: UsuarioRespuesta
