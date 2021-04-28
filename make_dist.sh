#!/bin/bash

set -e

SCRIPT_DIR=`pwd`
ARDUINO_ESP32_DIR="${SCRIPT_DIR}/arduino-esp32"
DIST_DIR="${SCRIPT_DIR}/dist"
DIST_REPO="https://github.com/mmakaay/arduino-esp32-unicore-no-mac-crc"

# Clone the repo through which the build is published.
/bin/rm -fR ${DIST_DIR}
git clone ${DIST_REPO} ${DIST_DIR}

# Remove some files that I don't want to copy to the dist.
/bin/rm -fR ${ARDUINO_ESP32_DIR}/.git
/bin/rm -fR ${ARDUINO_ESP32_DIR}/.github
/bin/rm -fR ${ARDUINO_ESP32_DIR}/.gitignore
/bin/rm -fR ${ARDUINO_ESP32_DIR}/.gitmodules
/bin/rm -fR ${ARDUINO_ESP32_DIR}/.travis.yml

# Remove existing files from the dist.
/bin/rm -fR ${DIST_DIR}/*

# Copy over the new files to the dist.
rsync -va ${ARDUINO_ESP32_DIR}/ ${DIST_DIR}/

