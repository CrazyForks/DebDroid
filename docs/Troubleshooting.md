# Troubleshooting Guide

## System reboot due to XFCE4

Newer releases of the XFCE4 desktop cause known problems within DebDroid environments. The issue is due to the power‑manager plugin, which assumes a traditional PC setup. This mismatch triggers excessive memory consumption, which can quickly exhaust the limited RAM on Android devices, resulting in a system reboot. To resolve this issue, users should look for a method that increases the available swap space of the device. Magisk-rooted users can simply flash the [`lin_os_swap_mod.zip`](../apk/lin_os_swap_mod.zip) archive in the module section of the Magisk app.
