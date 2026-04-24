#!/bin/bash

# Exit if no Bluetooth hardware
ls /sys/class/bluetooth/hci* >/dev/null 2>&1 || exit 0

if rfkill list bluetooth | grep -q "Soft blocked: yes"; then
  rfkill unblock bluetooth
  systemctl start bluetooth
else
  rfkill block bluetooth
  systemctl stop bluetooth
fi
