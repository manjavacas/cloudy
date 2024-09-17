
<p align="center">
    <img src="images/logo.png" alt="CLOUDY" width=40% />
</p>

**CLOUDY** automatiza la ejecución de experimentos en máquinas virtuales de [Google Cloud](https://console.cloud.google.com). Crea instancias y *buckets*, instala dependencias, ejecuta *scripts* de Python y maneja la limpieza de recursos.

## ✅ **¿Cómo funciona?**

El flujo de trabajo de **CLOUDY** es el siguiente:

1. El *script* `launch.sh` lanza un número determinado de instancias de máquinas virtuales, de acuerdo a las opciones especificadas en el fichero `config.json`.

2. En cada máquina virtual se ejecuta el *script* `setup.sh`, que instala dependencias, descarga un repositorio y ejecuta un *script* especificado.

3. La salida se guarda en un *bucket* existente, o lo crea en caso contrario.

<p align="center">
    <img src="images/diagram.png" alt="CLOUDY WORKFLOW" width=80% />
</p>

## 📄 **Scripts**

Este proyecto consta de los siguientes *scripts*:

-  `launch.sh`: crea instancias de máquinas virtuales en Google Cloud según la configuración definida en `config.json`.
-  `setup.sh`: se ejecuta en cada instancia creada, instala dependencias, clona un repositorio, ejecuta un *script* de Python y guarda los resultados en un *bucket* de Google Cloud.
-  `clean_cloud.sh`: limpia todas las instancias de máquinas virtuales y *buckets* en Google Cloud.
-  `Makefile`: facilita la ejecución de los *scripts* mediante comandos simples.

## 💻 **¿Cómo utilizar CLOUDY?**

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
        "SCRIPT_ARGS": "cloudy",
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
    - `SCRIPT_PATH` y `SCRIPT_ARGS`: ruta al *script* de Python que se encuentra en el repositorio y que queremos ejecutar, así como argumentos de entrada.
    - `SERVICE_ACCOUNT`: cuenta de servicio en GCP que vamos a utilizar. Debe contar con los permisos necesarios.


2. **Instalar las dependencias necesarias.**

    - `Google Cloud SDK`: necesario para interactuar con Google Cloud desde la línea de comandos.

    - `jq`: empleado para leer el archivo JSON de configuración.

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