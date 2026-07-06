from sqlalchemy import create_engine
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker

# Ruta del archivo SQLite — se crea automáticamente en la carpeta backend
SQLALCHEMY_DATABASE_URL = "sqlite:///./trashgo.db"

# El engine es la conexión principal a la base de datos.
# check_same_thread=False es necesario para SQLite con FastAPI,
# ya que FastAPI puede usar la misma conexión desde distintos hilos.
engine = create_engine(
    SQLALCHEMY_DATABASE_URL,
    connect_args={"check_same_thread": False},
)

# SessionLocal es la fábrica de sesiones. Cada petición abre una sesión
# propia y la cierra al terminar, evitando conflictos entre peticiones.
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

# Base es la clase de la que heredarán todos los modelos ORM.
# SQLAlchemy usa esta base para registrar las tablas.
Base = declarative_base()


def get_db():
    """
    Dependencia de FastAPI que provee una sesión de base de datos.
    Con 'yield' FastAPI garantiza que la sesión se cierra correctamente
    después de cada petición, incluso si ocurre un error.
    """
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()
