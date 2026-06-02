# Architecture

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
