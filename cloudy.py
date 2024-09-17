#!/usr/bin/env python3

import subprocess
import os
import sys

LAUNCH_SCRIPT = './scripts/launch.sh'
CLEAN_SCRIPT = './scripts/clean.sh'
CONFIG_FILE = 'config.json'

RED = '\033[31m'
RESET = '\033[0m'


def run_command(command):
    """
    Executes a command in the terminal and shows its output.
    """
    print(f"[CLOUDY] Running: {command}")
    try:
        subprocess.run(command, shell=True, check=True,
                       text=True, stdout=sys.stdout, stderr=sys.stderr)
    except subprocess.CalledProcessError as e:
        print_error(
            f"Command '{command}' failed with exit code {e.returncode}")
        print_error(e.stderr)
        sys.exit(1)

def print_error(message):
    """
    Prints an error message in red.
    """
    print(f"{RED}[CLOUDY] Error: {message}{RESET}", file=sys.stderr)


def launch():
    """
    Creates VM instances using the launch script.
    """
    if not os.path.isfile(CONFIG_FILE):
        print_error(f"The configuration file '{CONFIG_FILE}' does not exist.")
        sys.exit(1)
    print(
        f"[CLOUDY] Creating VM instances with the configuration in {CONFIG_FILE}...")
    run_command(f"bash {LAUNCH_SCRIPT} {CONFIG_FILE}")


def clean():
    """
    Cleans up Google Cloud resources using the cleanup script.
    """
    if not os.path.isfile(CONFIG_FILE):
        print_error(f"The configuration file '{CONFIG_FILE}' does not exist.")
        sys.exit(1)
    print("[CLOUDY] Clearing Google Cloud resources...")
    run_command(f"bash {CLEAN_SCRIPT} {CONFIG_FILE}")


def reset():
    """
    Deletes all cloud resources and then creates new ones.
    """
    clean()
    launch()


def help_message():
    """
    Displays the help message.
    """
    print("CLOUDY commands:")
    print(
        f"  python cloudy.py launch [CONFIG_FILE={CONFIG_FILE}] - Creates VM instances according to the specified configuration (default: {CONFIG_FILE}).")
    print(
        f"  python cloudy.py clean [CONFIG_FILE={CONFIG_FILE}]  - Deletes all instances and buckets in Google Cloud (requires {CONFIG_FILE}).")
    print("  python cloudy.py reset                            - Deletes all cloud resources and then creates new ones.")
    print("  python cloudy.py help                             - Displays this help.")


def main():
    """
    Processes command-line arguments.
    """
    if len(sys.argv) < 2:
        help_message()
        sys.exit(1)

    command = sys.argv[1].lower()

    if command == 'launch':
        launch()
    elif command == 'clean':
        clean()
    elif command == 'reset':
        reset()
    elif command == 'help':
        help_message()
    else:
        print_error(f"Unknown command '{command}'")
        help_message()
        sys.exit(1)


if __name__ == "__main__":
    main()
