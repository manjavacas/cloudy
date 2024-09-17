LAUNCH_SCRIPT := ./scripts/launch.sh
CLEAN_CLOUD_SCRIPT := ./scripts/clean_cloud.sh
CONFIG_FILE := config.json

all: launch

launch: $(CONFIG_FILE)
	@echo "Creando instancias de VM con la configuración $(CONFIG_FILE)..."
	@bash $(LAUNCH_SCRIPT) $(CONFIG_FILE)

clean:
	@echo "Limpiando recursos en Google Cloud..."
	@bash $(CLEAN_CLOUD_SCRIPT)

reset: clean launch

help:
	@echo "Objetivos disponibles:"
	@echo "  make launch [CONFIG_FILE=config.json] - Crea las instancias de VM según la configuración especificada (por defecto: config.json)."
	@echo "  make clean                            - Limpia todas las instancias y buckets en Google Cloud."
	@echo "  make reset                            - Limpia todos los recursos y luego crea nuevos."
	@echo "  make help                             - Muestra esta ayuda."
