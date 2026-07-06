from datetime import datetime

from sqlalchemy import (
    Boolean,
    Column,
    DateTime,
    Float,
    ForeignKey,
    Integer,
    String,
    Text,
)

# Importamos Base desde database.py — todos los modelos deben heredar de ella
# para que SQLAlchemy sepa que son tablas de la base de datos.
from database import Base


class PuntoComunitario(Base):
    # Nombre de la tabla en SQLite. Ahora guarda TODOS los puntos de recoleccion:
    # los 31 oficiales de la Municipalidad (es_oficial=True) y los que crean los
    # usuarios desde la app (es_oficial=False).
    __tablename__ = "puntos_comunitarios"

    # Clave primaria con autoincremento (1, 2, 3…)
    id = Column(Integer, primary_key=True, autoincrement=True)

    # Nombre del punto
    nombre = Column(String(150), nullable=False)

    # Descripción del punto — Text permite textos largos. Es opcional.
    descripcion = Column(Text, default="")

    # Coordenadas del punto en el mapa (obligatorias)
    latitud = Column(Float, nullable=False)
    longitud = Column(Float, nullable=False)

    # Sector o cuadrante al que pertenece (ej: "Cuadrante 1"). Opcional.
    sector = Column(String(150), default="")

    # Días en que se hace la recolección (texto libre, opcional)
    dias_recoleccion = Column(String(200), default="")

    # Horario de recolección (ej: "Desde las 21:00 h."). Opcional.
    horario = Column(String(200), default="")

    # Tipo de residuo que acepta el punto (ej: "Plástico", "Vidrio"). Opcional.
    tipo_residuo = Column(String(200), default="")

    # Id del usuario que creó el punto — ForeignKey lo conecta con la tabla usuarios.
    # Para los puntos oficiales queda en None (los siembra el sistema, no un usuario).
    autor_id = Column(Integer, ForeignKey("usuarios.id"))

    # Guardamos también el nombre del autor para mostrarlo sin consultar la otra
    # tabla. Para los oficiales es "Municipalidad".
    autor_nombre = Column(String(100))

    # True = punto oficial base (los 31 de la Municipalidad).
    # False = punto creado por un usuario desde la app.
    es_oficial = Column(Boolean, default=False)

    # Fecha y hora de creación — se asigna automáticamente al crear el registro
    created_at = Column(DateTime, default=datetime.utcnow)
