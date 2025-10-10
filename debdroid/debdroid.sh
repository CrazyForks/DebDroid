#!/system/bin/sh

# Checks for a matching debdroid configuration file
if [ ! -f /sdcard/debdroid/debdroid_env.sh ]; then
    echo "$0: Missing required configuration file: /sdcard/debdroid/debdroid_env.sh"
    exit 1
fi

# shellcheck disable=SC1091
. /sdcard/debdroid/debdroid_env.sh

# Prints HELP Usage
if [ $# -eq 0 ]; then
  echo "DebDroid frontend (https://github.com/NICUP14/DebDroid)
Author: NICUP14
Version: $DEBDROID_VER

Usage:
  debdroid.sh [OPTION] [SUBOPTION] [ARGUMENTS]

Options:
  run [COMMAND...]
      Runs the default Debdroid environment.
      If COMMAND is provided, it executes that command inside the environment.
      If no command is given, an interactive shell is started.

  list [patch|command]
      Lists available scripts.
      patch   - Lists all patch scripts in the patch directory.
      command - Lists all command scripts in the command directory.

  patch [PATCH_NAME]
      Applies the specified patch script from the patch directory.
      Example: debdroid.sh patch fix_network

  command [COMMAND_NAME]
      Executes the specified command script from the command directory.
      Example: debdroid.sh command setup_user

  resize (+|-)[SIZE]
      Resizes the debian image relative to the specified size.
      Example: debdroid.sh resize +2G

Notes:
  - Unrecognized options are treated the same as the 'run' option."
fi

debdroid_run() {
    # shellcheck disable=SC2068
    sh "$DEBDROID_SDHOME"/debdroid_mgr.sh "$DEBDROID_IMG" "$DEBDROID_ENV" "$DEBDROID_BIN" "$DEBDROID_LIB" $@
}

list_scripts() {
    $BUSYBOX find "$1" -type f -name "*.sh" -print | $BUSYBOX sed 's/\.sh$//'
}

# Configures parameters
DEBDROID_OPT=$1
DEBDROID_SUBOPT=$2

# Handles the "run" option
if [ "$DEBDROID_OPT" = "run"]; then
    shift
    debdroid_run

# Handles the "list" option
elif [ "$DEBDROID_OPT" = "list" ]; then
    if [ "$DEBDROID_SUBOPT" = "patch" ]; then
        echo "Available patches:"
        list_scripts "$DEBDROID_PATCH"
        exit
    elif [ "$DEBDROID_SUBOPT" = "command" ]; then
        echo "Available commands:" 
        list_scripts "$DEBDROID_CMD"
        exit
    else
        echo "$0: Unknown option: $DEBDROID_SUBOPT."
        exit 1
    fi

# Handles the "patch" option
elif [ "$DEBDROID_OPT" = "patch" ]; then
    PATCH="$DEBDROID_PATCH/$DEBDROID_SUBOPT.sh"
    if [ ! -f "$PATCH" ]; then
        echo "No such patch script: $PATCH." 
        exit 1
    fi

    echo "Applying patch script: \"$PATCH\"."
    # shellcheck disable=SC2068
    sh "$DEBDROID_SDHOME"/debdroid_mgr.sh "$DEBDROID_IMG" "$DEBDROID_ENV" "$DEBDROID_BIN" "$DEBDROID_LIB" \
        sh "$PATCH"

# Handles the "command" option
elif [ "$DEBDROID_OPT" = "command" ]; then
    CMD="$DEBDROID_CMD/$DEBDROID_SUBOPT.sh"
    if [ ! -f "$CMD" ]; then
        echo "No such command script: $CMD." 
        exit 1
    fi

    echo "Executing command script: \"$CMD\"."
    # shellcheck disable=SC2068
    sh "$DEBDROID_SDHOME"/debdroid_mgr.sh "$DEBDROID_IMG" "$DEBDROID_ENV" "$DEBDROID_BIN" "$DEBDROID_LIB" \
        sh "$CMD"

# Handles the "resize" option
elif [ "$DEBDROID_OPT" = "resize" ]; then
    sh "$DEBDROID_SDHOME"/debdroid_resize.sh "$DEBDROID_SUBOPT"

# Handles the unknown option case
# Functions the same as "debdroid.sh run"
else
    debdroid_run
fi