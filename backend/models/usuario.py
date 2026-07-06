from datetime import datetime

from sqlalchemy import Column, DateTime, Integer, String

# Importamos Base desde database.py — todos los modelos deben heredar de ella
# para que SQLAlchemy sepa que son tablas de la base de datos.
from database import Base


class Usuario(Base):
    # Nombre de la tabla en SQLite
    __tablename__ = "usuarios"

    # Clave primaria con autoincremento (1, 2, 3…)
    id = Column(Integer, primary_key=True, autoincrement=True)

    # Nombre del usuario, no puede estar vacío
    nombre = Column(String(100), nullable=False)

    # Email único por usuario — index=True acelera las búsquedas por email
    email = Column(String(150), unique=True, nullable=False, index=True)

    # Guardamos solo el hash de la contraseña, NUNCA la contraseña en texto plano
    password_hash = Column(String(255), nullable=False)

    # Fecha y hora de creación — se asigna automáticamente al crear el registro
    created_at = Column(DateTime, default=datetime.utcnow)
