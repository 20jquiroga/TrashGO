from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from auth import obtener_usuario_actual
from database import get_db
from models.punto_comunitario import PuntoComunitario
from models.usuario import Usuario
from schemas.punto_comunitario import (
    PuntoComunitarioCrear,
    PuntoComunitarioRespuesta,
)

# APIRouter agrupa rutas relacionadas. El prefix "/puntos-comunitarios" se antepone a todas.
router = APIRouter(prefix="/puntos-comunitarios", tags=["Puntos Comunitarios"])


@router.get("", response_model=list[PuntoComunitarioRespuesta])
def listar_puntos(db: Session = Depends(get_db)):
    """Devuelve TODOS los puntos de recolección: los 31 oficiales base y los
    que crean los usuarios, del más nuevo al más antiguo.
    No requiere token — cualquiera puede ver la lista."""
    # order_by con .desc() pone primero los puntos creados más recientemente
    puntos = db.query(PuntoComunitario).order_by(PuntoComunitario.created_at.desc()).all()
    return puntos


@router.post("", response_model=PuntoComunitarioRespuesta)
def crear_punto(
    datos: PuntoComunitarioCrear,
    usuario_actual: Usuario = Depends(obtener_usuario_actual),
    db: Session = Depends(get_db),
):
    """Crea un punto de recolección nuevo (es_oficial=False). Requiere token.
    El autor se toma del usuario autenticado."""
    # Construimos el punto tomando el autor del usuario que hizo la petición
    nuevo_punto = PuntoComunitario(
        nombre=datos.nombre,
        descripcion=datos.descripcion,
        latitud=datos.latitud,
        longitud=datos.longitud,
        sector=datos.sector,
        dias_recoleccion=datos.dias_recoleccion,
        horario=datos.horario,
        tipo_residuo=datos.tipo_residuo,
        autor_id=usuario_actual.id,
        autor_nombre=usuario_actual.nombre,
        es_oficial=False,   # lo crea un usuario, no es un punto oficial
    )
    db.add(nuevo_punto)
    db.commit()
    db.refresh(nuevo_punto)   # Recarga el objeto para obtener el id y created_at generados
    return nuevo_punto


@router.get("/{punto_id}", response_model=PuntoComunitarioRespuesta)
def obtener_punto(punto_id: int, db: Session = Depends(get_db)):
    """Devuelve un punto comunitario por su id. No requiere token."""
    punto = db.query(PuntoComunitario).filter(PuntoComunitario.id == punto_id).first()
    if punto is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Punto no encontrado",
        )
    return punto
