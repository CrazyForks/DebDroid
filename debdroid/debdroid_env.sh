#!/system/bin/sh

export DEBDROID_VER='1.1'

export DEBDROID_SDHOME=/sdcard/debdroid
export DEBDROID_IMG="$DEBDROID_SDHOME/img/debian.img"
export DEBDROID_CMD="$DEBDROID_SDHOME"/command
export DEBDROID_PATCH="$DEBDROID_SDHOME"/patch

export DEBDROID_HOME=/data/local/debdroid
export DEBDROID_BIN="$DEBDROID_HOME/bin"
export DEBDROID_LIB="$DEBDROID_HOME/lib"
export DEBDROID_ENV="$DEBDROID_HOME/mnt"
export BUSYBOX="$DEBDROID_HOME/bin/busybox"