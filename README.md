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

El primer comando de Redis debe responder `PONG` y la lectura de la clave debe devolver `Juan`. El script `scripts/infraestructura.ps1` reúne la descarga, una demostración independiente, inspección, persistencia y el inicio con Compose. Usa el puerto 26379 para la demostración temporal y requiere que esté libre. Para detener los servicios sin borrar los datos, ejecutar `docker compose down`.

Las credenciales de PostgreSQL corresponden a la demostración y son solo para uso local de práctica. La contraseña configurada es `123456!`. La configuración no está destinada a producción.

PostgreSQL aplica estas variables al inicializar un volumen vacío. Si ya existía el volumen de una ejecución anterior con otra contraseña, cambiar el archivo no modifica la contraseña de la base existente; hay que actualizarla por separado o comenzar con un volumen nuevo cuando los datos sean descartables.

## Inspección de los contenedores

Los siguientes comandos permiten revisar los elementos que se crean en la práctica:

```sh
docker images
docker compose ps
docker volume ls
docker network ls
docker logs compose-redis
docker exec -it compose-redis sh
```

El último comando abre una consola dentro del contenedor de Redis; `exit` vuelve a la consola del equipo. Dentro del contenedor puede abrirse `redis-cli` para probar `PING`, `SET nombre Juan` y `GET nombre` (salir de Redis con `exit`). Los puertos publicados son 6379 para Redis y 5432 para PostgreSQL; deben estar disponibles en el equipo.

## Comprobar la persistencia de Redis

```sh
docker exec compose-redis redis-cli set prueba_persistencia disponible
docker compose restart cache-service
docker exec compose-redis redis-cli get prueba_persistencia
```

La última orden debe devolver `disponible`. Redis guarda sus datos en `vol_compose_redis`, mientras que PostgreSQL utiliza `vol_compose_postgres`; ambos servicios comparten `red-infraestructura`. `docker compose down` conserva los volúmenes para volver a usarlos con `docker compose up -d`.
