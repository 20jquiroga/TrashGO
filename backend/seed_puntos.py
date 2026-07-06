from sqlalchemy.orm import Session

from models.punto_comunitario import PuntoComunitario
from seed_data import PUNTOS_OFICIALES


def sembrar_puntos_oficiales(db: Session) -> None:
    """
    "Siembra" (seed) los 31 puntos oficiales de la Municipalidad en la tabla
    puntos_comunitarios la PRIMERA vez que arranca el backend.

    Para NO duplicar: primero contamos cuántos puntos oficiales ya hay. Si ya
    existe al menos uno, no hacemos nada (asumimos que ya se sembraron antes).
    Si no hay ninguno, los insertamos todos con es_oficial=True.
    """
    # ¿Cuántos puntos oficiales hay ya en la base de datos?
    ya_existen = (
        db.query(PuntoComunitario)
        .filter(PuntoComunitario.es_oficial == True)  # noqa: E712
        .count()
    )

    # Si ya están, salimos sin insertar nada (evita duplicados en cada arranque).
    if ya_existen > 0:
        return

    # No hay ninguno todavía: insertamos los 31 puntos oficiales.
    for datos in PUNTOS_OFICIALES:
        punto = PuntoComunitario(
            nombre=datos["nombre"],
            descripcion="",
            latitud=datos["latitud"],
            longitud=datos["longitud"],
            sector=datos["sector"],
            dias_recoleccion=datos["dias_recoleccion"],
            horario=datos["horario"],
            tipo_residuo=datos["tipo_residuo"],
            autor_id=None,                 # no lo creó un usuario, lo siembra el sistema
            autor_nombre="Municipalidad",  # autor de los puntos oficiales
            es_oficial=True,               # marca de punto oficial base
        )
        db.add(punto)

    # Guardamos todos los puntos de una sola vez.
    db.commit()
    print(f"Seed: se insertaron {len(PUNTOS_OFICIALES)} puntos oficiales.")
