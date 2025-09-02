#!/system/bin/sh

# Checks for a matching debdroid configuration file
if [ ! -f /sdcard/debdroid/debdroid_env.sh ]; then
    echo "$0: Missing required configuration file: /sdcard/debdroid/debdroid_env.sh"
    exit 1
fi

# shellcheck disable=SC1091
. /sdcard/debdroid/debdroid_env.sh

# shellcheck disable=SC2068
sh "$DEBDROID_SDHOME"/debdroid_mgr.sh "$DEBDROID_IMG" "$DEBDROID_ENV" $@