from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from auth import obtener_usuario_actual
from database import get_db
from models.foro import Foro, Mensaje
from models.usuario import Usuario
from schemas.foro import ForoCrear, ForoRespuesta, MensajeCrear, MensajeRespuesta

# APIRouter agrupa rutas relacionadas. El prefix "/foros" se antepone a todas.
router = APIRouter(prefix="/foros", tags=["Foros"])


@router.get("", response_model=list[ForoRespuesta])
def listar_foros(db: Session = Depends(get_db)):
    """Devuelve todos los foros ordenados del más nuevo al más antiguo.
    No requiere token — cualquiera puede ver la lista."""
    # order_by con .desc() pone primero los foros creados más recientemente
    foros = db.query(Foro).order_by(Foro.created_at.desc()).all()
    return foros


@router.post("", response_model=ForoRespuesta)
def crear_foro(
    datos: ForoCrear,
    usuario_actual: Usuario = Depends(obtener_usuario_actual),
    db: Session = Depends(get_db),
):
    """Crea un tema nuevo en el foro. Requiere token.
    El autor se toma del usuario autenticado."""
    # Construimos el foro tomando el autor del usuario que hizo la petición
    nuevo_foro = Foro(
        titulo=datos.titulo,
        descripcion=datos.descripcion,
        autor_id=usuario_actual.id,
        autor_nombre=usuario_actual.nombre,
    )
    db.add(nuevo_foro)
    db.commit()
    db.refresh(nuevo_foro)   # Recarga el objeto para obtener el id y created_at generados
    return nuevo_foro


@router.get("/{foro_id}", response_model=ForoRespuesta)
def obtener_foro(foro_id: int, db: Session = Depends(get_db)):
    """Devuelve un foro por su id. No requiere token."""
    foro = db.query(Foro).filter(Foro.id == foro_id).first()
    if foro is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Foro no encontrado",
        )
    return foro


@router.get("/{foro_id}/mensajes", response_model=list[MensajeRespuesta])
def listar_mensajes(foro_id: int, db: Session = Depends(get_db)):
    """Devuelve los mensajes de un foro ordenados del más antiguo al más nuevo.
    No requiere token."""
    # order_by con .asc() muestra la conversación en orden cronológico
    mensajes = (
        db.query(Mensaje)
        .filter(Mensaje.foro_id == foro_id)
        .order_by(Mensaje.created_at.asc())
        .all()
    )
    return mensajes


@router.post("/{foro_id}/mensajes", response_model=MensajeRespuesta)
def crear_mensaje(
    foro_id: int,
    datos: MensajeCrear,
    usuario_actual: Usuario = Depends(obtener_usuario_actual),
    db: Session = Depends(get_db),
):
    """Agrega un mensaje a un foro. Requiere token.
    El autor se toma del usuario autenticado."""
    # Primero comprobamos que el foro exista antes de guardar el mensaje
    foro = db.query(Foro).filter(Foro.id == foro_id).first()
    if foro is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Foro no encontrado",
        )

    # Construimos el mensaje tomando el autor del usuario autenticado
    nuevo_mensaje = Mensaje(
        foro_id=foro_id,
        contenido=datos.contenido,
        autor_id=usuario_actual.id,
        autor_nombre=usuario_actual.nombre,
    )
    db.add(nuevo_mensaje)
    db.commit()
    db.refresh(nuevo_mensaje)   # Recarga el objeto para obtener el id y created_at generados
    return nuevo_mensaje
