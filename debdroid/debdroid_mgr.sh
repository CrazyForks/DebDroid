#!/system/bin/sh

# Mounts the chroot environment
start_environment()
{
    # Disables mount propagation
    $BUSYBOX mount --make-rprivate /

    # Links the standard streams to their file descriptor
    [ ! -e "/dev/fd" ]     && ln -s /proc/self/fd /dev/
    [ ! -e "/dev/stdin" ]  && ln -s /proc/self/fd/0 /dev/stdin
    [ ! -e "/dev/stdout" ] && ln -s /proc/self/fd/1 /dev/stdout
    [ ! -e "/dev/stderr" ] && ln -s /proc/self/fd/2 /dev/stderr

    # Links /dev/block loopback devices under /dev
    for idx in $($BUSYBOX seq 0 7); do
        [ ! -e /dev/loop"$idx" ] && ln -s /dev/block/loop"$idx" /dev/loop"$idx"
    done

    # Prepares the image mountpoint
    mkdir -p "$DEBDROIDMGR_ENV"
    $BUSYBOX mount -o loop "$DEBDROIDMGR_IMG" "$DEBDROIDMGR_ENV"

    # Copies the busybox binary
    if [ ! -f "$DEBDROIDMGR_ENV"/bin/busybox ]; then
        cp "$BUSYBOX" "$DEBDROIDMGR_ENV"/bin/busybox
        chmod 755 "$DEBDROIDMGR_ENV"/bin/busybox
    fi

    # Mounts the /proc filesystem
    mkdir -p "$DEBDROIDMGR_ENV"/proc
    ! $BUSYBOX mountpoint -q "$DEBDROIDMGR_ENV"/proc && $BUSYBOX mount -t proc /proc "$DEBDROIDMGR_ENV"/proc

    # Checks if the host has overlay support
    if ! grep -q overlay /proc/filesystems 2>/dev/null; then
        echo "$0: Missing overlay support, falling back to bind-mount for /dev."
    fi

    # Mounts the /dev filesystem (overlayed)
    mkdir -p "$DEBDROIDMGR_ENV"/dev
    mkdir -p "$DEBDROIDMGR_ENV"/mnt/dev-upper "$DEBDROIDMGR_ENV"/mnt/dev-work
    chmod 700 "$DEBDROIDMGR_ENV"/mnt/dev-upper "$DEBDROIDMGR_ENV"/mnt/dev-work
    ! $BUSYBOX mountpoint -q "$DEBDROIDMGR_ENV"/mnt/dev-upper && $BUSYBOX mount -t tmpfs tmpfs "$DEBDROIDMGR_ENV"/mnt/dev-upper
    if ! $BUSYBOX mount -t overlay overlay \
            -o lowerdir=/dev,upperdir="$DEBDROIDMGR_ENV"/mnt/dev-upper,workdir="$DEBDROIDMGR_ENV"/mnt/dev-work \
            "$DEBDROIDMGR_ENV"/dev 2>/dev/null; then
        echo "$0: Overlay failed, falling back to bind-mount for /dev."
        $BUSYBOX mount --bind /dev "$DEBDROIDMGR_ENV"/dev

        # Cleans the unused tmpfs
        $BUSYBOX umount "$DEBDROIDMGR_ENV"/mnt/dev-upper
        rm -rf "$DEBDROIDMGR_ENV"/mnt/dev-upper "$DEBDROIDMGR_ENV"/mnt/dev-work
    fi

    # Mounts the /dev/pts filesystem
    ! $BUSYBOX mountpoint -q "$DEBDROIDMGR_ENV"/dev/pts && $BUSYBOX mount -t devpts devpts "$DEBDROIDMGR_ENV"/dev/pts

    # Mounts the /dev/shm filesystem
    mkdir -p "$DEBDROIDMGR_ENV"/dev/shm
    ! $BUSYBOX mountpoint -q "$DEBDROIDMGR_ENV"/dev/shm && $BUSYBOX mount -o rw,nosuid,nodev,mode=1777 -t tmpfs tmpfs "$DEBDROIDMGR_ENV"/dev/shm

    # Mounts the /sys filesystem
    mkdir -p "$DEBDROIDMGR_ENV"/sys
    ! $BUSYBOX mountpoint -q "$DEBDROIDMGR_ENV"/sys && $BUSYBOX mount -r -t sysfs /sys "$DEBDROIDMGR_ENV"/sys

    # Mounts the /tmp filesystem
    mkdir -p "$DEBDROIDMGR_ENV"/tmp
    ! $BUSYBOX mountpoint -q "$DEBDROIDMGR_ENV"/tmp && $BUSYBOX mount -t tmpfs -o mode=1777,size=64M tmpfs "$DEBDROIDMGR_ENV"/tmp

    # Mounts the /system filesystem
    mkdir -p "$DEBDROIDMGR_ENV"/system
    ! $BUSYBOX mountpoint -q "$DEBDROIDMGR_ENV"/system && $BUSYBOX mount -r /system "$DEBDROIDMGR_ENV"/system

    # Mounts the /sdcard filesystem
    mkdir -p "$DEBDROIDMGR_ENV"/sdcard
    ! $BUSYBOX mountpoint -q "$DEBDROIDMGR_ENV"/sdcard && $BUSYBOX mount --bind /sdcard "$DEBDROIDMGR_ENV"/sdcard

    # Mounts the /debdroid/bin directory
    mkdir -p "$DEBDROIDMGR_ENV"/debdroid/bin
    ! $BUSYBOX mountpoint -q "$DEBDROIDMGR_ENV"/debdroid/bin && $BUSYBOX mount --bind "$DEBDROIDMGR_BIN" "$DEBDROIDMGR_ENV"/debdroid/bin
    chmod 755 "$DEBDROIDMGR_ENV"/debdroid/bin/*
    chmod +x "$DEBDROIDMGR_ENV"/debdroid/bin/*
    chown root:root "$DEBDROIDMGR_ENV"/debdroid/bin
    chown root:root "$DEBDROIDMGR_ENV"/debdroid/bin/*

    # Mounts the /debdroid/lib directory
    mkdir -p "$DEBDROIDMGR_ENV"/debdroid/lib
    ! $BUSYBOX mountpoint -q "$DEBDROIDMGR_ENV"/debdroid/lib && $BUSYBOX mount --bind "$DEBDROIDMGR_LIB" "$DEBDROIDMGR_ENV"/debdroid/lib
    chmod 644 "$DEBDROIDMGR_ENV"/debdroid/lib/*
    chown root:root "$DEBDROIDMGR_ENV"/debdroid/lib
    chown root:root "$DEBDROIDMGR_ENV"/debdroid/lib/*

    # Registers debdroid libraries in /etc/ld.so.preload
    true > "$DEBDROIDMGR_ENV"/etc/ld.so.preload
    for lib in "$DEBDROIDMGR_ENV"/debdroid/lib/*.so; do
        # shellcheck disable=SC2046
        echo /debdroid/lib/$(basename "$lib") >> "$DEBDROIDMGR_ENV"/etc/ld.so.preload
    done

    # Reserves 250MB for shared memory
    $BUSYBOX sysctl -w kernel.shmmax=268435456

    # Creates the /etc/resolv.conf file
    true > "$DEBDROIDMGR_ENV"/etc/resolv.conf
    for server in 1 2 3 4; do
        [ -z "$(getprop net.dns$server)" ] && break
        echo "nameserver $(getprop net.dns$server)" >> "$DEBDROIDMGR_ENV"/etc/resolv.conf
    done

    # Creates the /etc/hosts file
    true > "$DEBDROIDMGR_ENV"/etc/hosts
    echo "127.0.0.1     localhost $DEBDROIDMGR_HNAME" >> "$DEBDROIDMGR_ENV"/etc/hosts
    echo "::1           localhost ip6-localhost ip6-loopback" >> "$DEBDROIDMGR_ENV"/etc/hosts
    $BUSYBOX hostname "$DEBDROIDMGR_HNAME"

    # Sets the appropriate environment variables
    export TMPDIR=/tmp
    export PATH=/usr/bin:/usr/sbin:/bin:/usr/local/bin:/usr/local/sbin:/system/bin:/debdroid/bin:"$PATH"
}

# Unmounts the chroot environment
stop_environment()
{
    # Unmounts previously mounted filesystems
    for mount_point in debdroid/lib debdroid/bin sdcard system tmp sys sdcard mnt/dev-upper dev/pts dev/shm dev proc; do
        if $BUSYBOX mountpoint -q "$DEBDROIDMGR_ENV"/$mount_point; then
            $BUSYBOX umount "$DEBDROIDMGR_ENV"/${mount_point} 2>/dev/null || $BUSYBOX umount -l "$DEBDROIDMGR_ENV"/${mount_point} 2>/dev/null
        fi
    done

    # Unmounts the root filesystem
    ! $BUSYBOX mountpoint -q "$DEBDROIDMGR_ENV" && $BUSYBOX umount "$DEBDROIDMGR_ENV"
}

# Prints HELP Usage
if [ $# -eq 0 ]; then
    echo "$0: A lightweight utility to create safe, isolated chroot environments."
    echo "Usage: $0 <img> <mount-point> <bin-dir> <lib-dir> (<command>)?"
    exit
fi

# Checks for a matching architecture
ARCH=$(getprop ro.product.cpu.abi)
if [ "$ARCH" != "arm64-v8a" ]; then
    echo "$0: Unsupported architecture: $ARCH."
    echo "This script only works on arm64-v8a. (aarch64)"
    exit 1
fi

# Check if the user has root permissions 
if [ "$(id -u)" -ne 0 ]; then
    echo "$0: Missing required super-user permisions."
    exit 1
fi

# Checks for missing arguments
if [ $# -lt 4 ]; then
    echo "$0: Expected at least 4 arguments, but got $#."
    echo "Usage: $0 <img> <mount-point> <bin-dir> <lib-dir> (<command>)?"
    exit 1
fi


# Checks for popular busybox install locations
if [ -z "$BUSYBOX" ]; then
    if [ -x /sbin/busybox ]; then
        BUSYBOX=/sbin/busybox
    elif [ -x /system/bin/busybox ]; then
        BUSYBOX=/system/bin/busybox
    elif [ -x /system/xbin/busybox ]; then
        BUSYBOX=/system/xbin/busybox
    elif [ -x /data/local/bin/busybox ]; then
        BUSYBOX=/data/local/bin/busybox
    else
        echo "$0: Cannot locate the busybox binary."
        echo "Manually set it using the $BUSYBOX variable."
        exit 1
    fi
fi

# Configures parameters
DEBDROIDMGR_IMG=$1
DEBDROIDMGR_ENV=$2
DEBDROIDMGR_BIN=$3
DEBDROIDMGR_LIB=$4
shift 4
# shellcheck disable=SC2124
DEBDROIDMGR_EXEC=$@
DEBDROIDMGR_HNAME=debian

# Pass 1: Sets up the private mount namespace
if [ -z "$DEBDROIDMGR_MARK" ]; then
    export DEBDROIDMGR_MARK=1

    # Makes the script trigger "stop_environment" on exit
    trap 'stop_environment' EXIT INT TERM

    # Creates a private mount namespace
    # shellcheck disable=SC2086
    if ! $BUSYBOX unshare --mount sh "$0" "$DEBDROIDMGR_IMG" "$DEBDROIDMGR_ENV" "$DEBDROID_BIN" "$DEBDROID_LIB" $DEBDROIDMGR_EXEC; then
        echo "$0: Failed to create a private mountpoint."
        exit 1
    fi

    echo "$0: Stopping environment: \"$DEBDROIDMGR_ENV\""
    stop_environment

    unset DEBDROIDMGR_MARK

# Pass 2: Sets up the linux filesystem
else
    # Defines the default chroot command
    if [ -z "$DEBDROIDMGR_EXEC" ]; then
        DEBDROIDMGR_EXEC="/bin/su"
    fi

    echo "$0: Starting environment: \"$DEBDROIDMGR_ENV\""
    start_environment

    echo "$0: Running chroot command: \"$DEBDROIDMGR_EXEC\""
    # shellcheck disable=SC2086
    $BUSYBOX chroot "$DEBDROIDMGR_ENV" $DEBDROIDMGR_EXEC
fi
