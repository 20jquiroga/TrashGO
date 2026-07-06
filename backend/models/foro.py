from datetime import datetime

from sqlalchemy import Column, DateTime, ForeignKey, Integer, String, Text

# Importamos Base desde database.py — todos los modelos deben heredar de ella
# para que SQLAlchemy sepa que son tablas de la base de datos.
from database import Base


class Foro(Base):
    # Nombre de la tabla en SQLite — cada fila es un tema/hilo del foro
    __tablename__ = "foros"

    # Clave primaria con autoincremento (1, 2, 3…)
    id = Column(Integer, primary_key=True, autoincrement=True)

    # Título del tema del foro
    titulo = Column(String(150), nullable=False)

    # Descripción larga del tema — Text permite textos sin límite fijo
    descripcion = Column(Text, nullable=False)

    # Id del usuario que creó el foro — ForeignKey lo conecta con la tabla usuarios
    autor_id = Column(Integer, ForeignKey("usuarios.id"), nullable=False)

    # Guardamos también el nombre del autor para mostrarlo sin consultar la otra tabla
    autor_nombre = Column(String(100), nullable=False)

    # Fecha y hora de creación — se asigna automáticamente al crear el registro
    created_at = Column(DateTime, default=datetime.utcnow)


class Mensaje(Base):
    # Nombre de la tabla en SQLite — cada fila es una respuesta dentro de un foro
    __tablename__ = "mensajes"

    # Clave primaria con autoincremento (1, 2, 3…)
    id = Column(Integer, primary_key=True, autoincrement=True)

    # Id del foro al que pertenece el mensaje — lo conecta con la tabla foros
    foro_id = Column(Integer, ForeignKey("foros.id"), nullable=False)

    # Contenido del mensaje — Text permite textos largos
    contenido = Column(Text, nullable=False)

    # Id del usuario que escribió el mensaje
    autor_id = Column(Integer, ForeignKey("usuarios.id"), nullable=False)

    # Guardamos también el nombre del autor para mostrarlo directamente
    autor_nombre = Column(String(100), nullable=False)

    # Fecha y hora de creación — se asigna automáticamente al crear el registro
    created_at = Column(DateTime, default=datetime.utcnow)
