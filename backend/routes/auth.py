from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from auth import crear_token, hash_password, obtener_usuario_actual, verificar_password
from database import get_db
from models.usuario import Usuario
from schemas.usuario import TokenRespuesta, UsuarioLogin, UsuarioRegistro, UsuarioRespuesta

# APIRouter agrupa rutas relacionadas. El prefix "/auth" se antepone a todas.
router = APIRouter(prefix="/auth", tags=["Autenticación"])


@router.post("/registro", response_model=TokenRespuesta)
def registro(datos: UsuarioRegistro, db: Session = Depends(get_db)):
    """Crea una cuenta nueva y devuelve un token JWT listo para usar."""

    # Verificamos que el email no esté ya registrado
    existe = db.query(Usuario).filter(Usuario.email == datos.email).first()
    if existe:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="El email ya está registrado",
        )

    # Creamos el nuevo usuario con la contraseña hasheada
    nuevo_usuario = Usuario(
        nombre=datos.nombre,
        email=datos.email,
        password_hash=hash_password(datos.password),
    )
    db.add(nuevo_usuario)
    db.commit()
    db.refresh(nuevo_usuario)   # Recarga el objeto para obtener el id y created_at generados

    # Generamos el token con el email como identificador ("sub" = subject)
    token = crear_token({"sub": nuevo_usuario.email})

    return TokenRespuesta(
        access_token=token,
        usuario=UsuarioRespuesta.model_validate(nuevo_usuario),
    )


@router.post("/login", response_model=TokenRespuesta)
def login(datos: UsuarioLogin, db: Session = Depends(get_db)):
    """Inicia sesión y devuelve un token JWT si las credenciales son correctas."""

    # Buscamos el usuario por email
    usuario = db.query(Usuario).filter(Usuario.email == datos.email).first()

    # Usamos el mismo mensaje para email inexistente y contraseña incorrecta.
    # Si dijéramos "email no encontrado" daríamos pistas a atacantes sobre
    # qué emails están registrados.
    error_credenciales = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Correo o contraseña incorrectos",
    )

    if not usuario:
        raise error_credenciales

    if not verificar_password(datos.password, usuario.password_hash):
        raise error_credenciales

    # Credenciales correctas — generamos y devolvemos el token
    token = crear_token({"sub": usuario.email})

    return TokenRespuesta(
        access_token=token,
        usuario=UsuarioRespuesta.model_validate(usuario),
    )


@router.get("/perfil", response_model=UsuarioRespuesta)
def perfil(usuario_actual: Usuario = Depends(obtener_usuario_actual)):
    """Devuelve los datos del usuario autenticado.
    Solo funciona si se envía un token JWT válido en el header Authorization."""
    return UsuarioRespuesta.model_validate(usuario_actual)
