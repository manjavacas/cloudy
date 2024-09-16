# ☁️ **CLOUDY**

**CLOUDY** es un proyecto que proporciona *scripts* básicos para gestionar instancias de máquinas virtuales y *buckets* en [Google Cloud](https://console.cloud.google.com). Los scripts permiten crear instancias, instalar dependencias, ejecutar scripts de Python y manejar la limpieza de recursos.

## 📄 **Scripts**

Este proyecto consta de los siguientes scripts:

1. `create_vms.sh`: crea instancias de máquinas virtuales en Google Cloud según la configuración definida en `config.json`.
2. `setup.sh`: se ejecuta en cada instancia creada, instala dependencias, clona un repositorio, ejecuta un script de Python y guarda los resultados en un bucket de Google Cloud.
3. `clean_cloud.sh`: limpia todas las instancias de máquinas virtuales y buckets en Google Cloud.
4. `Makefile`: facilita la ejecución de los scripts mediante comandos simples.

## 💻 **Cómo utilizar CLOUDY**

0. **Prerrequisitos**.

   Debes contar con una [cuenta de servicio en GCP](https://cloud.google.com/iam/docs/service-accounts-create?hl=es-419) con los permisos requeridos por *Compute engine* y *Cloud Storage* (ej. administrador de almacenamiento).

1. **Configurar `config.json`.**

   Define tu configuración en el archivo `config.json`, ubicado en el directorio raíz del proyecto. Por ejemplo:

   ```json
    {
    "N_VMS": 1,
    "INSTANCE_NAME_BASE": "vm-id",
    "BUCKET_NAME": "bucket-id",
    "REPO_NAME": "cloudy",
    "REPO_URL": "https://github.com/manjavacas/cloudy.git",
    "SCRIPT_PATH": "foo/foo.py",
    "DEPENDENCIES": "numpy pandas",
    "SERVICE_ACCOUNT": "your-service@account.iam.gserviceaccount.com",
    "SETUP_SCRIPT": "setup.sh",
    "MACHINE_TYPE": "e2-medium",
    "ZONE": "europe-southwest1-b",
    "IMAGE_FAMILY": "ubuntu-2004-lts",
    "IMAGE_PROJECT": "ubuntu-os-cloud",
    "BUCKET_ZONE": "eu"
    }
    ```

    Los principales campos a editar son:

    - `INSTANCE_NAME_BASE` y `BUCKET_NAME`: identificador de las instancias y *bucket* creados.
    - `REPO_NAME` y `REPO_URL`: repositorio a clonar. En él se ubica el código que queremos ejecutar.
    - `DEPENDENCIES`: dependencias requeridas para ejecutar el *script*.
    - `SCRIPT_PATH`: ruta al *script* de Python que se encuentra en el repositorio y que queremos ejecutar.
    - `SERVICE_ACCOUNT`: cuenta de servicio en GCP que vamos a utilizar. Debe contar con los permisos necesarios.


2. **Instalar las dependencias necesarias.**

    - *Google Cloud SDK*: necesario para interactuar con Google Cloud desde la línea de comandos.

    - *jq*: empleado para leer el archivo JSON de configuración.

3. **Ejecución.**

    - Para crear las instancias de máquinas virtuales, ejecuta:

    ```bash
    make launch
    ```

    - Para limpiar todas las instancias y *buckets*, ejecuta:

    ```bash
    make clean
    ```

    - Para eliminar máquinas y *buckets* y volver a lanzar:

    ```bash
    make reset
    ```