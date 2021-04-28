#!/bin/bash

set -e

SCRIPT_DIR=`pwd`
ARDUINO_ESP32_DIR="${SCRIPT_DIR}/arduino-esp32"
DIST_DIR="${SCRIPT_DIR}/dist"
DIST_REPO="https://github.com/mmakaay/arduino-esp32-unicore-no-mac-crc"

if [ ! -e ${ARDUINO_ESP32_DIR} ]; then
    echo "Build dir ${ARDUINO_ESP32_DIR} does not exist."
    echo "Was the build.sh script run? Aborting ..."
    exit 1
fi

# Clone the repo through which the build is published.
if [ ! -e ${DIST_DIR} ]; then
    echo "Cloning target repository ..."
    git clone ${DIST_REPO} ${DIST_DIR}
fi

# Remove some files that I don't want to copy to the dist.
/bin/rm -fR ${ARDUINO_ESP32_DIR}/.git
/bin/rm -fR ${ARDUINO_ESP32_DIR}/.github
/bin/rm -fR ${ARDUINO_ESP32_DIR}/.gitignore
/bin/rm -fR ${ARDUINO_ESP32_DIR}/.gitmodules
/bin/rm -fR ${ARDUINO_ESP32_DIR}/.travis.yml

# Remove existing files from the dist.
echo "Cleaning existing dist files"
/bin/rm -fR ${DIST_DIR}/*

# Copy over the new files to the dist.
echo "Copying new dist files"
rsync -va ${ARDUINO_ESP32_DIR}/ ${DIST_DIR}/

echo ""
echo "----------------------------------------------------------------------------"
echo "Repo files update. You can now commit the files to GitHub if you like.
echo "----------------------------------------------------------------------------"
