LAUNCH_SCRIPT := ./scripts/launch.sh
CLEAN_SCRIPT := ./scripts/clean.sh
CONFIG_FILE := config.json

all: launch

launch: $(CONFIG_FILE)
	@echo "Creating VM instances with the configuration in $(CONFIG_FILE)..."
	@bash $(LAUNCH_SCRIPT) $(CONFIG_FILE)

clean:
	@echo "Clearing Google Cloud resources..."
	@bash $(CLEAN_SCRIPT) $(CONFIG_FILE)

reset: clean launch

help:
	@echo "CLOUDY commands:"
	@echo "  make launch [CONFIG_FILE=config.json] - Creates VM instances according to the specified configuration (default: config.json)."
	@echo "  make clean [CONFIG_FILE=config.json]  - Deletes all instances and buckets in Google Cloud (requires config.json)."
	@echo "  make reset                            - Deletes all cloud resources and then creates new ones."
	@echo "  make help                             - Displays this help."

