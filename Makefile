CONFIG_FILE := config.json
LAUNCH_SCRIPT := ./scripts/launch.sh
CLEAN_CLOUD_SCRIPT := ./scripts/clean_cloud.sh

all: launch

launch:
	@echo "Creando instancias de VM..."
	@bash $(LAUNCH_SCRIPT)

clean:
	@echo "Limpiando recursos en Google Cloud..."
	@bash $(CLEAN_CLOUD_SCRIPT)

reset: clean launch

help:
	@echo "Objetivos disponibles:"
	@echo "  make launch      - Crea las instancias de VM según la configuración especificada."
	@echo "  make clean       - Limpia todas las instancias y buckets en Google Cloud."
	@echo "  make reset       - Limpia todos los recursos y luego crea nuevos."
	@echo "  make help        - Muestra esta ayuda."
