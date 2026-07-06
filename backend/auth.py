from datetime import datetime, timedelta

from fastapi import Depends, HTTPException, status
from fastapi.security import OAuth2PasswordBearer
from jose import JWTError, jwt
from passlib.context import CryptContext
from sqlalchemy.orm import Session

from database import get_db
from models.usuario import Usuario

# --- Constantes de configuración ---

# Clave secreta para firmar los tokens. En producción debería estar en una
# variable de entorno, no escrita directamente en el código.
SECRET_KEY = "trashgo-secret-2024-arica"

# Algoritmo de firma del JWT (HS256 es el más común para proyectos web)
ALGORITHM = "HS256"

# El token dura 7 días antes de expirar
ACCESS_TOKEN_EXPIRE_DAYS = 7


# --- Hashing de contraseñas ---

# CryptContext configura passlib para usar bcrypt.
# bcrypt aplica un proceso de hashing lento a propósito para dificultar ataques.
pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")


def hash_password(password: str) -> str:
    """Convierte una contraseña en texto plano a su hash bcrypt."""
    return pwd_context.hash(password)


def verificar_password(plain: str, hashed: str) -> bool:
    """Compara una contraseña en texto plano contra su hash guardado en la BD.
    Devuelve True si coinciden, False si no."""
    return pwd_context.verify(plain, hashed)


# --- Tokens JWT ---

def crear_token(data: dict) -> str:
    """Genera un JWT firmado con los datos proporcionados y una fecha de expiración."""
    payload = data.copy()

    # Calculamos cuándo expira el token sumando los días configurados
    expiracion = datetime.utcnow() + timedelta(days=ACCESS_TOKEN_EXPIRE_DAYS)
    payload["exp"] = expiracion   # "exp" es el campo estándar de expiración en JWT

    # jwt.encode firma el payload con la clave secreta y el algoritmo elegido
    token = jwt.encode(payload, SECRET_KEY, algorithm=ALGORITHM)
    return token


# --- Dependencia para rutas protegidas ---

# OAuth2PasswordBearer extrae automáticamente el token del header
# "Authorization: Bearer <token>" en cada petición protegida.
oauth2_scheme = OAuth2PasswordBearer(tokenUrl="auth/login")


def obtener_usuario_actual(
    token: str = Depends(oauth2_scheme),
    db: Session = Depends(get_db),
) -> Usuario:
    """Dependencia que verifica el JWT y devuelve el usuario autenticado.
    Se usa en las rutas protegidas con Depends(obtener_usuario_actual).

    Lanza HTTPException 401 si el token es inválido, expiró o el usuario no existe.
    """
    # Preparamos el error genérico que devolveremos si algo falla
    credenciales_invalidas = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="No se pudo validar el token",
        headers={"WWW-Authenticate": "Bearer"},
    )

    try:
        # Decodificamos el token y verificamos su firma y expiración
        payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])

        # El "sub" (subject) es el campo donde guardamos el email del usuario
        email: str = payload.get("sub")
        if email is None:
            raise credenciales_invalidas

    except JWTError:
        # JWTError cubre tokens mal firmados, expirados o con formato incorrecto
        raise credenciales_invalidas

    # Buscamos al usuario en la base de datos usando el email del token
    usuario = db.query(Usuario).filter(Usuario.email == email).first()
    if usuario is None:
        raise credenciales_invalidas

    return usuario
