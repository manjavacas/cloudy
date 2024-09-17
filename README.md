
<p align="center">
    <img src="images/logo.png" alt="CLOUDY" width=50% />
</p>

![License](https://img.shields.io/badge/license-GPLv3-blue)
[![Release](https://badgen.net/github/release/manjavacas/cloudy)]()
[![Contributors](https://badgen.net/github/contributors/manjavacas/cloudy)]() 

**CLOUDY** automates the execution of experiments on [Google Cloud](https://console.cloud.google.com). It creates instances and buckets, installs dependencies, runs Python scripts, and handles resource cleanup.

## ⚙️ **How it works?**

The workflow of **CLOUDY** comprises the following steps:

1. The script `launch.sh` launches a specified number of virtual machine instances, according to the options specified in the `config.json` file.

2. The script `setup.sh` is executed in each VM to install dependencies, download the specified repository and run the Python script indicated.

3. The output is saved to an existing bucket, or a new one is created as required.

4. The instances are automatically deleted once their execution has finished.

<p align="center">
    <img src="images/diagram.png" alt="DIAGRAM" width=80% />
</p>

## 📄 **Scripts**

This project consists of the following scripts:

- `launch.sh`: creates VM instances on Google Cloud according to the configuration defined in `config.json`.
- `setup.sh`: runs on each VM instance. Installs dependencies, clones a repository, runs a Python script, and saves the results to a Google Cloud bucket, creating it if necessary.
- `clean.sh`: cleans up all virtual machine instances and buckets on Google Cloud.
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

    The main options to edit are:

    - `INSTANCE_NAME_BASE` and `BUCKET_NAME`: identifiers for the created instances and bucket.
    - `REPO_NAME` and `REPO_URL`: repository to clone. This is where the code you want to execute is located.
    - `SCRIPT_PATH` and `SCRIPT_ARGS`: path to the Python script you want to execute in the repository, along with its input arguments.
    - `DEPENDENCIES`: dependencies required to run the Python script.
    - `SERVICE_ACCOUNT`: GCP service account to be used. It must have the necessary permissions.

3. **Run CLOUDY**

    - To launch the virtual machine instances, run:

    ```bash
    make launch
    ```

    - To clean up all instances and buckets, run:

    ```bash
    make clean
    ```

    - To delete machines and buckets and then relaunch, run:

    ```bash
    make reset
    ```