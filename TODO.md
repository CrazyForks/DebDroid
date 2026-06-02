# TODO List

For DebDroid v1.2:

- [X] Prompt resize during install.
- [X] Prompt for backup/overwrite of `debian.img` during install.
- [X] Implement resize functionality.
- [X] Update old binaries  (`e2fsck`, `resize2fs`, `truncate`).
- [X] Run `e2fsck` before mounting the image in `debdroid.sh`
- [X] Update binaries (`truncate`, `resize2fs`, `e2fsck`, `busybox`)
- [X] Implement feature-based configuration mechanism for DebDroid.
- [X] Security check for mounted image in `debdroid_resize.sh`.
- [X] Implement robust unshare check. (`/proc/self/ns/mnt`)
- [ ] Implement DebDroid PID loggers and locks for more robust checks.
- [ ] Implement a smart configuration system for `debdroid_mgr.sh`
- [ ] Update command functionality for DebDroid.
- [ ] Update README:
  - Offload large sections into `docs`.
  - Add preloading and binary mentions to security considerations.
  - Document `debdroid_mgr.sh` configuration flags.
  - Document and mention the container runtime.

For future versions of DebDroid:

- [ ] Multi-arch support (planned for v1.3)
- [ ] Rescue shell functionality for DebDroid. (planned for v1.3)
- [ ] GPU acceleration.
- [ ] Add QoL commands:
  - [X]`command/update`: Environment updater script.
  - [ ] `command/vncserver`: Easy vnc server management.
  - [ ] `command/sshserver`: Easy ssh server management.
