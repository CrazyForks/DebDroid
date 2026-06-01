# DebDroid - Debian On Android

> [!IMPORTANT]
> Previous versions (v1.0 and v1.1) contain critical security bugs and missing functionality. Users are strongly encouraged to update DebDroid to the latest version (v1.2). The update does not interfere with existing DebDroid setups.

DebDroid repurposes your old, unused Android devices into compact Debian workstations. It offers an lightweight sandboxed Linux environment meant to replace Raspberry Pi or other single-board computers. Since it runs on top of native Android, you get a full Linux userland for a fraction of the space with no additional hardware required, making it an attractive, plug-and-play solution for developers and sysadmins who need a portable, low-maintenance server on hand.

Check out the [photo gallery](GALLERY.md)!

## Join the Discussions

> ![NOTE]
> Starting from v1.2, discussions have moved to discord for easier communication with users.

Have questions, ideas, or feedback? Then go ahead and join our **[discord server](https://discord.gg/5aKx85eZc)**!

## DebDroid is not Termux

Unlike Termux or Proot, which run Linux tools via Android-compiled binaries or user-space emulation, DebDroid runs a real Debian chroot directly on Android. It ships its own programs, libraries, patches and links key Android filesystems into the Debian environment, providing near-native Linux functionality and the ability to run almost any Debian-compatible program.

## Features

- Small and portable.
- No external dependencies.
- Runs a minimal Debian Linux userland in a isolated chroot environment.
- Mounts key Android system paths to provide near-native Linux functionality.
- Employs `unshare` to isolate Android mountpoints from the chroot environment.
- Supports `/dev` overlayfs, creating a writable layer over device files without modifying the real `/dev`.

**Linux+Android on the same device:** DebDroid manages a persistent chroot container inside Android that isolates the Linux subsystem, while keeping the underlying Android OS intact. This lets your run Linux workloads side-by-side with your regular Android apps, all without dual-boot, flashing or loss of Android functionality.

**Flexible access:** You can interact with DebDroid locally through a terminal emulator, ADB or remotely via SSH, VNC, RDP and many others!

**Debian environment on a Android device:** DebDroid provides a complete Linux workspace with a wide array of supported utilities so you can perform software development, system‑administration, or other tasks directly on the device without needing a separate computer.

**Turn your idle Android devices into a headless server:** Whether you need a web server, CI runner, IoT gateway, or VPN endpoint, an old Android device becomes a self‑contained, energy‑efficient server that you can deploy anywhere without the hassle of wiring, power adapters, or a separate SBC.

## Requirements

Supported Android versions:

- Requires an `aarch64` Android device running Lollipop or later (released Nov 2014).
- Covers devices launched in the past ~12 years, from Android 5 through Android 14.

Newer devices running Android 15 or later already include native KVM‑based virtualization, making DebDroid unnecessary for those platforms.

Additional requirements:

- The device must be rooted.
- You’ll need at least 1 GB of free storage (5 GB is recommended for a comfortable experience).

## Disclaimer

The software is provided "as is", without warranty of any kind, express or implied, including but not limited to the warranties of merchantability, fitness for a particular purpose, and noninfringement. In no event shall the authors or copyright holders be liable for any claim, damages, or other liability, whether in an action of contract, tort, or otherwise, arising from, out of, or in connection with the software or the use or other dealings in the software.

## Security implications

### Vulnerabilities

Most of the older Android devices supported by DebDroid have already reached end‑of‑life (EOL), meaning they no longer receive security patches or kernel updates. That means any vulnerabilities discovered past their last system update remain unpatched, making these environments unsuitable for handling confidential data or production-grade workloads. DebDroid is intended for tasks where exposing personal information is not a concern.

### RNG and Cryptography

This project patches certain system utilities, providing compatibility with the Android system by overriding Linux's randomness mechanisms, such as the `getrandom` syscall, `getentropy` function and glibc’s `arc4random` functions. It replaces the default cryptographic randomness with direct `/dev/urandom` reads. This is generally safe on modern Linux/Android, because the kernel ensures `/dev/urandom` provides high-quality entropy.

## Installation Guide

> [!NOTE]
> Once installed, DebDroid can be safely updated by simply re-running the install script.It performs the necessary script and package updates packages without overwriting the existing image.

This guide is written for novice users. You only need basic knowledge of Android, like installing apps from unknown sources, extracting an archive, and a little experience using a terminal (command line).

### What You Need

Before starting, make sure you have these apps installed on your device:

- [Terminal Emulator](apk/TerminalEmulator.apk) - lets you access Android's command-line interface.
- [Hacker's Keyboard](apk/HackersKeyboard.apk) - an advanced keyboard that makes typing commands easier.
- [Root Explorer](https://play.google.com/store/apps/details?id=com.speedsoftware.rootexplorer&hl=en-US) - lets you browse and manage Android files.

Alternatively, you can use a free alternative to Root Explorer, such as [Explorer](https://play.google.com/store/apps/details?id=com.speedsoftware.explorer) or [MiXplorer](https://play.google.com/store/apps/details?id=com.mixplorer.silver).

### Step 1: Downloading and Extracting the Project

1. Download the project zip file: [DebDroid-main.zip](https://github.com/NICUP14/DebDroid/archive/refs/heads/main.zip).
2. Locate `DebDroid-main.zip` in your `Download` folder (`/sdcard/Download`).
3. Extract the `DebDroid-main.zip` archive inside the `Download` folder. You can use an application such as `Root Explorer` or `MiXplorer` for this task.

After extraction, you should have a folder named `DebDroid-main` in your `Download` folder.

### Step 2: Installing DebDroid

1. Open the `Terminal Emulator` app.
2. Type the following commands, pressing Enter after each one:

```bash
su
cd /sdcard/Download/DebDroid-main
sh install.sh
```

The script will automatically install DebDroid files in:

- `/data/local/debdroid`
- `/sdcard/debdroid`

After that, DebDroid is ready to use!

## Quickstart Guide

### Usage

To display DebDroid's help page, run:

```bash
/sdcard/debdroid/debdroid.sh help
```

```txt
Usage:
  debdroid.sh [OPTION] [SUBOPTION] [ARGUMENTS]

Options:
  run [COMMAND...]
      Runs the default Debdroid environment.
      If COMMAND is provided, it executes that command inside the environment.
      If no command is given, an interactive shell is started.

  list
      Lists all command scripts in the command directory.

  command [COMMAND_NAME]
      Executes the specified command script from the command directory.
      Example: debdroid.sh command setup_user

  resize [SIZE]
      Resizes the debian image to the specified size.
      Example: debdroid.sh resize 5G

Notes:
  - Unrecognized options are treated the same as the 'run' option.
```

### DebDroid Hierarchy

```txt
/sdcard/debdroid/
├── environment       # User environment config
├── debdroid_env.sh   # DebDroid environment config (paths, environment variables)
├── debdroid.sh       # DebDroid user interface script
├── debdroid_mgr.sh   # DebDroid backend script (mounts and manages chroot)
├── img/
│   └── debian.img    # Debian root filesystem
└── command/          # Command scripts
```

Scripts placed inside the `command` folder can be easily executed to conduct specific tasks within the chroot environment, such as updating the system or managing ssh & vnc servers (coming soon!). Consult the [running commands section](#running-commands).

```txt
/data/local/debdroid/
├── bin            # External binaries
│   └── debinit    # DebDroid bootstrap script
├── lib            # External libraries
└── mnt            # Debian mount point
```

Programs stored in `bin` can be run directly inside the chroot as it is mounted and appended to `$PATH`. Libraries placed inside `lib` will be automatically preloaded, allowing for custom overrides and patches without any modifications to Linux system files.

`bin/debinit` is the DebDroid bootstrap script executed at the start of every  session. It runs specifically in the Linux userland to address persistent environment issues and quirks.

For security reasons, the session spawns a clean login shell without inheriting the host's environment variables. Any required variable must be explicitly set in `debdroid/environment`, which is automatically sourced by `bin/debinit`.

### Running Interactive Sessions

1. Open the `Terminal Emulator` app.
2. Type the following commands, pressing Enter after each one:

```bash
su
sh /sdcard/debdroid/debdroid.sh
```

This launches the environment and gives you a shell inside Debian.

Inside the chroot shell, users can execute the `exit` command to leave the environment and automatically unmount the filesystems.

### Running Commands

You can run a specific command inside the chroot without starting an interactive shell. DebDroid provides pre-made command scripts located in `/sdcard/debdroid/command`, which automate common tasks such as maintenance, setup, or service management.

To list available command scripts, run:

```bash
su
sh /sdcard/debdroid/debdroid.sh list
```

To execute a command script, run:

```bash
su
sh /sdcard/debdroid/debdroid.sh command <command-name>
```

To execute other commands directly inside the chroot, run:

```bash
su
sh /sdcard/debdroid/debdroid.sh apt update
# or (explicit version)
sh /sdcard/debdroid/debdroid.sh run apt update
```

This will execute the `apt update` command directly in the chroot environment.

## Notes

### Image Resizing

> [!WARNING]
> Starting from v1.2, the size passed to the resizer is no longer relative!

The Debian root filesystem (debian.img) in DebDroid has a fixed size. If you need more space, you can easily expand it using the built-in resize helper.

The following command expands the debian environment to 5GB:

```bash
su
sh /sdcard/debdroid/debdroid.sh resize 5G
```

For additional usage instructions, run:

```bash
su
sh /sdcard/debdroid/debdroid.sh resize
```

- Make sure the image is **not mounted** when resizing.
- Ensure you have **enough free storage** on your device to accommodate the new image size.

### User Networking

Due to Android group restrictions, users inside the DebDroid chroot need to be added to the `inet` group to access networking tools.

```bash
usermod -aG inet <username>
```

After this, the user should be able to use networking commands like `ping`.

## Troubleshooting

### System reboot due to XFCE4

Newer releases of the XFCE4 desktop cause known problems within DebDroid environments. The issue is due to the power‑manager plugin, which assumes a traditional PC setup. This mismatch triggers excessive memory consumption, which can quickly exhaust the limited RAM on Android devices, resulting in a system reboot. To resolve this issue, users should look for a method that increases the available swap space of the device. Magisk-rooted users can simply flash the [`lin_os_swap_mod.zip`](apk/lin_os_swap_mod.zip) archive in the module section of the Magisk app.

## Patched Programs

The following programs have been analyzed and patched to run properly within the DebDroid chroot environment:

- `gpg` – GNU Privacy Guard
- `sshd` – OpenSSH server
- `snapd` – Snap daemon (WIP)

## Credits

The project wouldn't have existed without:

- [Meefik](https://github.com/meefik) for maintaining the android build of `busybox`.
- [LineageOS team](https://github.com/LineageOS) for maintaining the android build of `e2fsprogs`.
- [Janithcooray](https://github.com/janithcooray) for developing the Magisk swap module.
