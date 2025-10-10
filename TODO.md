# TODO List

- [ ] Add QoL commands:
  - `command/init`: Startup script (inet + apt patch + ssh patch + mkdir)
  - `command/update`: Environment updater script (possibly also debdroid updater)
  - `command/sshserver`: Easy management of the ssh server outside of debdroid
- [X] Implement resize functionality.
- [ ] Update old binaries  (`e2fsck`, `resize2fs`, `truncate`)
- [ ] Implement install failsafes against accidental overwrites.
- [ ] Prompt resize during install.
