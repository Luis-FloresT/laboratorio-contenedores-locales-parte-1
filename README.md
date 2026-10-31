# Laboratorio de contenedores locales — Parte 1

Configuración de Redis 7 y PostgreSQL 16 con Docker Compose, basada en la demostración de clase. Los servicios comparten una red y usan volúmenes para conservar sus datos.

## Ejecución

Con Docker Desktop y Docker Compose instalados y en funcionamiento, desde esta carpeta:

```sh
docker compose up -d
docker compose ps
docker exec compose-redis redis-cli ping
docker exec compose-redis redis-cli set nombre Juan
docker exec compose-redis redis-cli get nombre
docker exec compose-postgres psql -U usuario_uleam -d db_integracion -c 'SELECT current_database(), current_user;'
```

El primer comando de Redis debe responder `PONG` y la lectura de la clave debe devolver `Juan`. El script `scripts/infraestructura.ps1` reúne estos pasos para PowerShell. Para detener los servicios sin borrar los datos, ejecutar `docker compose down`.

Las credenciales de PostgreSQL corresponden a la demostración y son solo para uso local de práctica. La contraseña configurada es `123456!`. La configuración no está destinada a producción.

PostgreSQL aplica estas variables al inicializar un volumen vacío. Si ya existía el volumen de una ejecución anterior con otra contraseña, cambiar el archivo no modifica la contraseña de la base existente; hay que actualizarla por separado o comenzar con un volumen nuevo cuando los datos sean descartables.
