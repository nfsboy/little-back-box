#!/usr/bin/env bash

# Author: Dmitri Popov, dmpop@linux.com

#######################################################################
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.

# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.

# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#######################################################################

CONFIG_DIR=$(dirname "$0")
CONFIG="${CONFIG_DIR}/config.cfg"
source "$CONFIG"

# Set the ACT LED to heartbeat
sudo sh -c "echo heartbeat > /sys/class/leds/led0/trigger"

# Shutdown after a specified period of time (in minutes) if no device is connected.
#sudo shutdown -h $SHUTD "Shutdown is activated. To cancel: sudo shutdown -c"
if [ $DISP = true ]; then
    oled r
    oled +b "Device ready"
    oled +c "Insert storage"
    sudo oled s
fi

# Wait for a USB storage device (e.g., a USB flash drive)
STORAGE=$(ls /dev/* | grep "$STORAGE_DEV" | cut -d"/" -f3)

#check if storage mount point is empty
if [ "$(ls -A $STORAGE_MOUNT_POINT)" ]; then
    mv "$STORAGE_MOUNT_POINT" "$STORAGE_MOUNT_POINT"-`date +%Y.%m.%d.%H.%M.%S`
    mkdir "$STORAGE_MOUNT_POINT"
fi



while [ -z "${STORAGE}" ]; do
    sleep 1
    STORAGE=$(ls /dev/* | grep "$STORAGE_DEV" | cut -d"/" -f3)
done

# When the USB storage device is detected, mount it
mount /dev/"$STORAGE_DEV" "$STORAGE_MOUNT_POINT"

# Checker for storage disconnection
"${CONFIG_DIR}/card-backup-background-check.sh" &


# in case that the card is not connected and the disk is just waiting is better to end the process and shutdown rpi
sudo shutdown -h $SHUTD "Shutdown is activated. To cancel: sudo shutdown -c"

# Set the ACT LED to blink at 1000ms to indicate that the storage device has been mounted
sudo sh -c "echo timer > /sys/class/leds/led0/trigger"
sudo sh -c "echo 1000 > /sys/class/leds/led0/delay_on"

if [ $DISP = true ]; then
    storsize=$(df /dev/"$STORAGE_DEV"  -h --output=size | sed '1d' | tr -d ' ')
#    storused=$(df /dev/"$STORAGE_DEV"  -h --output=pcent | sed '1d' | tr -d ' ')
    storfree=$(df /dev/"$STORAGE_DEV"  -h --output=avail | sed '1d' | tr -d ' ')
    oled r
    oled +b "Storage $storsize OK"
    oled +c "Free: $storfree"
    oled +d "Shutdown in ${SHUTD}m"
    sudo oled s
fi

umount /dev/"$STORAGE_DEV"

"${CONFIG_DIR}/card-backup-run.sh" 1
