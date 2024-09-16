# **CLOUDY**

**CLOUDY** es un proyecto que proporciona scripts básicos para gestionar instancias de máquinas virtuales y buckets en Google Cloud. Los scripts permiten crear instancias, instalar dependencias, ejecutar scripts de Python y manejar la limpieza de recursos.

## **Scripts**

Este proyecto consta de los siguientes scripts:

1. `create_vms.sh`: crea instancias de máquinas virtuales en Google Cloud según la configuración definida en `config.json`.
2. `setup.sh`: se ejecuta en cada instancia creada, instala dependencias, clona un repositorio, ejecuta un script de Python y guarda los resultados en un bucket de Google Cloud.
3. `clean_cloud.sh`: limpia todas las instancias de máquinas virtuales y buckets en Google Cloud.
4. `Makefile`: facilita la ejecución de los scripts mediante comandos simples.

## **Cómo utilizar CLOUDY**

0. **Prerrequisitos**.

   Debes contar con una cuenta de servicio

1. **Configurar `config.json`.**

   Define tu configuración en el archivo `config.json`. Por ejemplo:

   ```json
    {
    "N_VMS": 4,
    "INSTANCE_NAME_BASE": "instance_name",
    "BUCKET_NAME": "bucket_name",
    "REPO_NAME": "repo_name",
    "REPO_URL": "https://github.com/user/repo_name.git",
    "SCRIPT_PATH": "script_name",
    "DEPENDENCIES": "numpy pandas",
    "SERVICE_ACCOUNT": "service@account.iam.gserviceaccount.com",
    "SETUP_SCRIPT": "setup.sh",
    "MACHINE_TYPE": "e2-medium",
    "ZONE": "europe-southwest1-b",
    "IMAGE_FAMILY": "ubuntu-2004-lts",
    "IMAGE_PROJECT": "ubuntu-os-cloud",
    "BUCKET_ZONE": "eu"
    }
    ```
2. **Instalar las dependencias necesarias.**

    - *Google Cloud SDK*: necesario para interactuar con Google Cloud desde la línea de comandos.

    - *jq*: empleado para leer el archivo JSON de configuración.

3. **Ejecución.**

    - Para crear las instancias de máquinas virtuales, ejecuta:

    ```bash
    make launch
    ```

    - Para limpiar todas las instancias y buckets, ejecuta:

    ```bash
    make clean
    ```