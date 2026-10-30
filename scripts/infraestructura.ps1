# Descarga de imágenes utilizadas en el laboratorio
docker pull redis:7-alpine
docker pull postgres:16-alpine
docker images --format "table {{.Repository}}\t{{.Tag}}\t{{.ID}}\t{{.Size}}"

# Iniciar servicios desde la carpeta raíz del proyecto
docker compose up -d

# Comprobaciones de Redis
docker exec compose-redis redis-cli ping
docker exec compose-redis redis-cli set nombre "Juan"
docker exec compose-redis redis-cli get nombre
docker exec compose-redis redis-cli save

# Comprobación de PostgreSQL
docker exec compose-postgres psql -U usuario_uleam -d db_integracion -c "SELECT current_database(), current_user;"
