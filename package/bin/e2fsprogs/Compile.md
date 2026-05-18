# Compile Guide for e2fsprogs

## Requirements

- Requires a Linux desktop device.
- A working internet connection to download the `Android NDK` and `e2fsprogs` source code. (check below)

Required packages:

- `autoconf`
- `coreutils`/`busybox`
- `git`
- `make`
- `unzip`

## Environment Preparation

First, create and populate the local cross-compilation environment:

```bash
mkdir -p <env-dir>
tar -C <env-dir> -xf <download-dir>/env_e2fsprogs.tar.gz
```

Then, grab a copy of the `Android NDK` from [Android Developers](https://developer.android.com/ndk/downloads/) and extract it to the environment.

```bash
unzip -d <env-dir> <download-dir>/android-ndk-r27d.zip
```

At last, clone the `LineageOS/android_external_e2fsprogs` (v1.47.2) github repository using `git`:

```bash
cd <env-dir>
git clone https://github.com/LineageOS/android_external_e2fsprogs.git
cd android_external_e2fsprogs
git checkout 8045c66384370e8539576c9cdc073674737c3ffc
```

## Expected Structure

After completing the preparation phase, your local environment should look like this:

```txt
Environment
├── android_external_e2fsprogs   # LineageOS' source of e2fsprogs
├── android-ndk-r27d             # Android NDK (r27d)
├── configure_e2fsprogs.sh       # Configuration script
├── env_android.sh               # Cross-compilation environment
└── include                      # Android Compatibility Definitions
```

## Compilation Steps

Run the following commands to configure e2fsprogs. This process uses `autoconf` to probe the system and prepare the build environment:

```bash
cd <env-dir>
source ./env_android.sh
./configure_e2fsprogs.sh
```

Then, change directory into the `android_external_e2fsprogs` folder and invoke the build tool:

```bash
cd android_external_e2fsprogs
make -j $(nproc)
```

## Optional Tweaks

### Feature Flags

- `--disable-addrsan`
- `--disable-backtrace` (enabled)
- `--disable-bmap-stats`
- `--disable-debugfs`
- `--disable-defrag`
- `--disable-e2initrd-helper`
- `--disable-evms`
- `--disable-fsck` (enabled)
- `--disable-fuse2fs` (enabled)
- `--disable-htree`
- `--disable-imager`
- `--disable-largefile`
- `--disable-libblkid`
- `--disable-libuuid`
- `--disable-mmp`
- `--disable-nls` (enabled)
- `--disable-option-checking`
- `--disable-resizer`
- `--disable-rpath`
- `--disable-swapfs`
- `--disable-tdb`
- `--disable-testio-debug`
- `--disable-threads`
- `--disable-threadsan`
- `--disable-tls`
- `--disable-ubsan`
- `--disable-uuid` (enabled)
- `--disable-uuidd` (enabled)
