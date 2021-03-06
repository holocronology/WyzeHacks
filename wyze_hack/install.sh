#!/bin/sh

# Redirecting console logs to SD card
if [ -d /media/mmcblk0p1/ ];
then
    exec >/media/mmcblk0p1/install.log
    exec 2>&1
fi

echo "Starting wyze hack installer..."

$THIS_DIR/playwav.sh $THIS_DIR/snd/begin.wav 50

if [ -f /media/mmcblk0p1/debug/.copyfiles ];
then
    echo "Copying files for debugging purpose..."
    rm -rf /media/mmcblk0p1/debug/system
    rm -rf /media/mmcblk0p1/debug/etc

    # Copying system and etc back to SD card for analysis
    cp -rL /system /media/mmcblk0p1/debug
    cp -rL /etc /media/mmcblk0p1/debug
fi

# Always try to enable telnetd
echo "Enabling telnetd..."
echo 1>/configs/.Server_config

# Swapping shadow file so we can telnetd in without password. This
# is for debugging purpose.
export PASSWD_SHADOW='root::10933:0:99999:7:::'
$THIS_DIR/bind_etc.sh

# Version check
source $THIS_DIR/app_ver.inc

if [ -z "$WYZEAPP_VER" ];
then
    echo "Wyze version not found!!!"
    $THIS_DIR/playwav.sh $THIS_DIR/snd/failed.wav 50
    exit 1
fi

echo "Current Wyze software version is $WYZEAPP_VER"
echo "Installing WyzeHacks version $THIS_VER"

# Updating user config if exists
if [ -f /media/mmcblk0p1/config.inc ];
then
    echo "Copying configuration files..."
    sed 's/\r$//' /media/mmcblk0p1/config.inc > $WYZEHACK_CFG
fi

if [ ! -f $WYZEHACK_CFG ];
then
    echo "Configuration file not found, aborting..."
    $THIS_DIR/playwav.sh $THIS_DIR/snd/failed.wav 50
    exit 1
fi

# Copying wyze_hack scripts
echo "Copying wyze hack binary..."
cp $THIS_BIN $WYZEHACK_BIN

# Hook app_init.sh
echo "Hooking up boot script..."
if ! $THIS_DIR/hook_init.sh;
then
    echo "Hooking up boot script failed"
    $THIS_DIR/playwav.sh $THIS_DIR/snd/failed.wav 50
    exit 1
fi

$THIS_DIR/playwav.sh $THIS_DIR/snd/finished.wav 50
echo "Done, reboot in 10 seconds..."
sleep 10

rm /media/mmcblk0p1/version.ini.old	
mv /media/mmcblk0p1/version.ini /media/mmcblk0p1/version.ini.old
