
<p align="center">
    <img src="images/logo.png" alt="CLOUDY" width=50% />
</p>

![License](https://img.shields.io/badge/license-GPLv3-blue)
[![Release](https://badgen.net/github/release/manjavacas/cloudy)]()
[![Contributors](https://badgen.net/github/contributors/manjavacas/cloudy)]() 

**CLOUDY** automates the execution of experiments on [Google Cloud](https://console.cloud.google.com). It creates VM instances and buckets, installs dependencies, runs Python scripts, and handles resource cleanup.

## ⚙️ **How it works?**

The workflow of **CLOUDY** comprises the following steps:

1. The script `launch.sh` prepares a VM instance, according to the options specified in the `config.json` file.

2. The script `setup.sh` is executed in the VM to install dependencies and run the Python script indicated.

3. The output is saved to an existing bucket, or a new one is created as required.

4. The instance is automatically deleted once its execution has finished.

<p align="center">
    <img src="images/diagram.png" alt="DIAGRAM" width=80% />
</p>

## 📄 **Scripts**

This project consists of the following scripts:

- `launch.sh`: creates a VM instance on Google Cloud according to the configuration defined in `config.json`. It also downloads and copies your repository to the VM instance.
- `setup.sh`: runs on the VM instance. Installs dependencies, runs your Python script, and saves the results to a Google Cloud bucket, creating it if necessary.
- `clean.sh`: cleans up all VM instances and buckets on Google Cloud.
- `Makefile`: enables the execution of the scripts through simple commands.

## 💻 **How to use CLOUDY?**

1. **Prerequisites**

   First, create a [service account on GCP](https://cloud.google.com/iam/docs/service-accounts-create?hl=en) with the required permissions for Compute Engine and Cloud Storage (e.g., *storage administrator*, *compute instances administrator*).

   Then, install the following dependencies:

    - `Google Cloud SDK`: required to interact with Google Cloud from the command line.

    - `jq`: used to read the JSON configuration file.

2. **Edit `config.json`**

   Define your custom configuration in the `config.json` file, located in the root directory of the project. For example:

   ```json
    {
        "INSTANCE_NAME": "vm-id",
        "BUCKET_NAME": "bucket-id",
        "REPO_URL": "https://github.com/manjavacas/cloudy.git",
        "SCRIPT_PATH": "foo/foo.py",
        "SCRIPT_ARGS": "cloudy",
        "DEPENDENCIES": "numpy pandas",
        "SERVICE_ACCOUNT": "your-service@account.iam.gserviceaccount.com",
        "SETUP_SCRIPT": "setup.sh",
        "MACHINE_TYPE": "n2-standard-2",
        "ZONE": "europe-southwest1-b",
        "IMAGE_FAMILY": "ubuntu-2004-lts",
        "IMAGE_PROJECT": "ubuntu-os-cloud",
        "BUCKET_ZONE": "eu"
    }
    ```

    The main options to edit are:

    - `INSTANCE_NAME` and `BUCKET_NAME`: identifiers for the created instance and bucket.
    - `REPO_URL`: the repository to clone. This is where the code you want to execute is located.
    - `SCRIPT_PATH` and `SCRIPT_ARGS`: path to the Python script you want to execute in the repository, along with its input arguments.
    - `DEPENDENCIES`: dependencies required to run the Python script.
    - `SERVICE_ACCOUNT`: GCP service account to be used. It must have the necessary permissions.

3. **Run CLOUDY**

    a. **Using `Makefile`**

    - To launch a VM instance, run:

    ```bash
    $ make launch
    ```

    - To clean up all VM instances and buckets, run:

    ```bash
    $ make clean
    ```

    - To delete VM instances and buckets and then relaunch, run:

    ```bash
    $ make reset
    ```

    b. **Using `cloudy.py`**

    Alternatively, you can use the Python script `cloud.py` for the same operations:

    ```bash
    $ python cloudy.py launch
    $ python cloudy.py clean
    $ python cloudy.py reset
    ```