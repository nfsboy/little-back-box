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

iteration="$1"

CARD_POINT="CARD_DEV${iteration}"
CARD=${!CARD_POINT}
echo "next point for backup is $CARD"

# if var is empty, exit
if [ -z "$CARD" ]
then
    sudo sh -c "echo 0 > /sys/class/leds/led0/brightness"
    echo "No setup for $CARD_POINT in $CONFIG"
    exit 0
fi


CARD_READER=($(ls /dev/* | grep "$CARD" | cut -d"/" -f3))
until [ ! -z "${CARD_READER[0]}" ]
  do
  sleep 1
  CARD_READER=($(ls /dev/* | grep "$CARD" | cut -d"/" -f3))
done

sudo shutdown -c

# Set the ACT LED to heartbeat
sudo sh -c "echo heartbeat > /sys/class/leds/led0/trigger"

# Wait for a USB storage device (e.g., a USB flash drive)
STORAGE=$(ls /dev/* | grep "$STORAGE_DEV" | cut -d"/" -f3)
while [ -z "${STORAGE}" ]
do
    sleep 1
    STORAGE=$(ls /dev/* | grep "$STORAGE_DEV" | cut -d"/" -f3)
done

# When the USB storage device is detected, mount it
mount /dev/"$STORAGE_DEV" "$STORAGE_MOUNT_POINT"

# Set the ACT LED to blink at 1000ms to indicate that the storage device has been mounted
sudo sh -c "echo timer > /sys/class/leds/led0/trigger"
sudo sh -c "echo 1000 > /sys/class/leds/led0/delay_on"

# If the card reader is detected, mount it and obtain its UUID
mount /dev"/${CARD_READER[0]}" "$CARD_MOUNT_POINT"

# Set the ACT LED to blink at 500ms to indicate that the card has been mounted
sudo sh -c "echo 500 > /sys/class/leds/led0/delay_on"

# If display support is enabled, notify that the card has been mounted
if [ $DISP = true ]; then
    oled r
    oled +a "Backup $iteration"
    oled +b "Backup progress:"
    oled +c "Starting..."
    sudo oled s 
fi

# Create  a .id random identifier file if doesn't exist
cd "$CARD_MOUNT_POINT"
if [ ! -f *.id ]; then
    random=$(echo $RANDOM)
    touch $(date -d "today" +"%Y%m%d%H%M")-$random.id
fi
ID_FILE=$(ls *.id)
ID="${ID_FILE%.*}"
cd

# Set the backup path
BACKUP_PATH="$STORAGE_MOUNT_POINT"/"$ID"
# Perform backup using rsync
if [ $DISP = true ]; then
    rsync -avhW --info=progress2 --exclude "*.id" "$CARD_MOUNT_POINT"/ "$BACKUP_PATH" | "${CONFIG_DIR}/oled-rsync-progress.sh" exclude.txt $iteration
else
    rsync -avhW --info=progress2 --exclude "*.id" "$CARD_MOUNT_POINT"/ "$BACKUP_PATH"
fi
if [ "$?" -eq "0" ]; then
    STATUS="complete"
else
    STATUS="FAILED"
fi

# files verification
diffcount=$(rsync -nai --delete "$CARD_MOUNT_POINT"/ "$BACKUP_PATH" | grep ">f" | grep -v ".id" | wc -l )

echo "Different count number is $diffcount"

if [ "$diffcount" -eq "0" ]; then
    STATUS="verified"
else
    STATUS="FAILED $diffcount"
fi

# If display support is enabled, notify that the backup is complete
if [ $DISP = true ]; then
    oled r
    oled +a "Backup $iteration"
    oled +b "Backup $STATUS"
    oled +c "Finishing..."
    sudo oled s
fi

# Finish
storsize=$(df /dev/"$STORAGE_DEV"  -h --output=size | sed '1d' | tr -d ' ')
storfree=$(df /dev/"$STORAGE_DEV"  -h --output=avail | sed '1d' | tr -d ' ')

sync
umount /dev/"$STORAGE_DEV"
umount /dev"/${CARD_READER[0]}"

if [ $SHUTD_AFTER_BACKUP = true ]; then
    sudo shutdown -h $SHUTD "Shutdown is activated. To cancel: sudo shutdown -c"
fi
if [ $DISP = true ]; then
    oled r
    oled +a "Backup $iteration"
    oled +b "Backup $STATUS"
    oled +c "Storage: $storsize"
    oled +d "Free: $storfree"
    if [ $SHUTD_AFTER_BACKUP = true ]; then
	oled +d "Shutdown in ${SHUTD}m"
    fi
    sudo oled s
fi
sudo sh -c "echo 0 > /sys/class/leds/led0/brightness"

nextIteration="$(($iteration + 1))"

echo "Next iteration number is $nextIteration"

"${CONFIG_DIR}/card-backup-run.sh" $nextIteration