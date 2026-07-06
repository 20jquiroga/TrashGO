from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from database import Base, SessionLocal, engine

# Importamos el modelo ANTES de create_all para que SQLAlchemy lo registre
# y pueda crear la tabla "usuarios" en la base de datos.
from models import usuario  # noqa: F401 — el import es necesario aunque no se use directamente

# Importamos el modelo del foro ANTES de create_all para que se creen sus tablas
# "foros" y "mensajes" en la base de datos.
from models import foro  # noqa: F401 — el import es necesario aunque no se use directamente

# Importamos el modelo de puntos comunitarios ANTES de create_all para que se
# cree su tabla "puntos_comunitarios" en la base de datos.
from models import punto_comunitario  # noqa: F401 — el import es necesario aunque no se use directamente

from routes.auth import router as auth_router
from routes.foro import router as foro_router
from routes.punto_comunitario import router as puntos_comunitarios_router

# Crea todas las tablas registradas en Base al arrancar el servidor.
# Si la tabla ya existe, SQLAlchemy la ignora (no la borra ni la recrea).
Base.metadata.create_all(bind=engine)

# "Sembramos" los 31 puntos oficiales la primera vez que arranca el servidor.
# Abrimos una sesion de base de datos, ejecutamos el seed y la cerramos.
# El seed no duplica: si los puntos oficiales ya existen, no hace nada.
from seed_puntos import sembrar_puntos_oficiales  # noqa: E402

_db = SessionLocal()
try:
    sembrar_puntos_oficiales(_db)
finally:
    _db.close()

# Instancia principal de la aplicación FastAPI
app = FastAPI(
    title="TrashGo API",
    version="1.0",
    description="Backend de TrashGo — gestión de residuos para Arica, Chile.",
)

# Configuración de CORS para permitir peticiones desde la app Flutter
# durante el desarrollo. En producción se restringiría a dominios específicos.
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],      # Acepta peticiones desde cualquier origen
    allow_credentials=True,
    allow_methods=["*"],      # Permite todos los métodos (GET, POST, PUT, DELETE…)
    allow_headers=["*"],      # Acepta cualquier cabecera HTTP
)

# Registramos el router de autenticación — agrega /auth/registro, /auth/login, /auth/perfil
app.include_router(auth_router)

# Registramos el router del foro — agrega /foros y /foros/{id}/mensajes
app.include_router(foro_router)

# Registramos el router de puntos comunitarios — agrega /puntos-comunitarios y /puntos-comunitarios/{id}
app.include_router(puntos_comunitarios_router)


@app.get("/")
def raiz():
    """Ruta de bienvenida para confirmar que la API está en línea."""
    return {"mensaje": "TrashGo API funcionando correctamente"}


@app.get("/health")
def health_check():
    """Ruta de verificación de estado usada por monitores y balanceadores."""
    return {"status": "ok"}
