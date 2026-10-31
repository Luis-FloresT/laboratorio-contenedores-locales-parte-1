<#
Laboratorio de contenedores locales — Parte 1
Estudiante: Luis Enrique Flores Toala
Asignatura: Integración de Sistemas y Plataformas

Ejecutar con PowerShell desde la carpeta raíz del proyecto:
    pwsh ./scripts/infraestructura.ps1
Requiere Docker Desktop o un motor Docker disponible. El puerto 6379 y el
5432 deben estar libres. Este archivo crea y elimina únicamente un contenedor
y un volumen de demostración con los nombres indicados abajo; no usa rm -f
sobre recursos existentes. Los servicios Compose quedan en ejecución.
#>
$ErrorActionPreference = 'Stop'
$raiz = Split-Path -Parent $PSScriptRoot
Set-Location $raiz
$contenedorDemo = 'laboratorio-demo-redis'
$volumenDemo = 'laboratorio-demo-redis-datos'

function Invoke-Docker {
    & docker @args
    if ($LASTEXITCODE -ne 0) { throw "Falló docker $($args -join ' ')" }
}

# Verificar que el motor y Compose están disponibles.
Invoke-Docker version
Invoke-Docker compose version

# Descargar las imágenes utilizadas y listar las imágenes locales.
Invoke-Docker pull redis:7-alpine
Invoke-Docker pull postgres:16-alpine
Invoke-Docker images
Invoke-Docker image inspect redis:7-alpine
# Para eliminar una imagen que ya no necesites: docker image rm NOMBRE:ETIQUETA

# Comprobar que no se sobrescriban recursos de una ejecución anterior.
$existente = & docker ps -aq --filter "name=^/${contenedorDemo}$"
if ($LASTEXITCODE -ne 0) { throw 'No se pudo consultar los contenedores.' }
if ($existente) { throw "Ya existe el contenedor $contenedorDemo; revísalo antes de continuar." }
$volumenExistente = & docker volume ls -q --filter "name=^${volumenDemo}$"
if ($LASTEXITCODE -ne 0) { throw 'No se pudo consultar los volúmenes.' }
if ($volumenExistente) { throw "Ya existe el volumen $volumenDemo; revísalo antes de continuar." }

# Crear un volumen y ejecutar Redis de forma independiente (-d) con persistencia AOF.
# Se publica en 26379 para no interferir con el servicio Compose del puerto 6379.
Invoke-Docker volume create $volumenDemo
Invoke-Docker run -d --name $contenedorDemo -p 26379:6379 -v "${volumenDemo}:/data" --restart unless-stopped redis:7-alpine redis-server --appendonly yes

# Listar contenedores, ver registros e inspeccionar el volumen y la red.
Invoke-Docker ps -a
Invoke-Docker logs $contenedorDemo
# Para seguir los registros en vivo: docker logs -f laboratorio-demo-redis
Invoke-Docker volume ls
Invoke-Docker volume inspect $volumenDemo
Invoke-Docker network ls

# Ejecutar comandos en el contenedor: conexión, escritura, lectura y persistencia.
Invoke-Docker exec $contenedorDemo redis-cli ping
Invoke-Docker exec $contenedorDemo redis-cli set estudiante 'Luis Enrique Flores Toala'
Invoke-Docker exec $contenedorDemo redis-cli get estudiante
Invoke-Docker exec $contenedorDemo redis-cli set contador 0
Invoke-Docker exec $contenedorDemo redis-cli incr contador
Invoke-Docker exec $contenedorDemo redis-cli get contador
Invoke-Docker exec $contenedorDemo redis-cli save

# Copiar el respaldo de Redis desde el contenedor al equipo y verificar que existe.
$respaldoTemporal = [System.IO.Path]::GetTempFileName()
try {
    Invoke-Docker cp "${contenedorDemo}:/data/dump.rdb" $respaldoTemporal
    Get-Item $respaldoTemporal | Select-Object Name, Length
} finally {
    Remove-Item -LiteralPath $respaldoTemporal -Force -ErrorAction SilentlyContinue
}

# Una consola dentro del contenedor puede abrirse con:
# docker exec -it laboratorio-demo-redis sh
# Dentro de ella: redis-cli; luego PING, GET estudiante y exit para salir.
# Aquí se ejecuta una orden de shell sin solicitar una terminal interactiva.
Invoke-Docker exec $contenedorDemo sh -c 'ls -la /data'

# Reiniciar y leer la misma clave para comprobar que persiste.
Invoke-Docker restart $contenedorDemo
Invoke-Docker exec $contenedorDemo redis-cli get estudiante

# Detener y eliminar solamente los recursos de la demostración independiente.
Invoke-Docker stop $contenedorDemo
Invoke-Docker rm $contenedorDemo
Invoke-Docker volume rm $volumenDemo

# Levantar los dos servicios declarados en docker-compose.yaml y consultar su estado.
Invoke-Docker compose up -d
Invoke-Docker compose ps
Invoke-Docker exec compose-redis redis-cli ping
Invoke-Docker exec compose-redis redis-cli set estudiante 'Luis Enrique Flores Toala'
Invoke-Docker exec compose-redis redis-cli get estudiante
# PostgreSQL puede tardar unos segundos en inicializar su volumen.
$listo = $false
for ($intento = 0; $intento -lt 30; $intento++) {
    & docker exec compose-postgres pg_isready -U usuario_uleam -d db_integracion *> $null
    if ($LASTEXITCODE -eq 0) { $listo = $true; break }
    Start-Sleep -Seconds 2
}
if (-not $listo) { throw 'PostgreSQL no terminó de iniciar.' }
Invoke-Docker exec compose-postgres psql -U usuario_uleam -d db_integracion -c 'SELECT current_database(), current_user;'

# Al terminar la práctica, este comando detiene los servicios sin borrar sus datos:
# docker compose down
