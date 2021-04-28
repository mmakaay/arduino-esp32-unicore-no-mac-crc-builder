#!/bin/bash

set -e

# Used by esp32-arduino-lib-builder code.
export ARDUINO_BRANCH="idf-release/v3.3"
export IDF_BRANCH="release/v3.3"
export IDF_TARGET="esp32"

# Used by this script.
SCRIPT_DIR=`pwd`
LIB_BUILDER_REPO="https://github.com/espressif/esp32-arduino-lib-builder.git"
LIB_BUILDER_BRANCH="release/v3.3"
LIB_BUILDER_DIR="${SCRIPT_DIR}/esp32-arduino-lib-builder"
ARDUINO_ESP32_REPO="https://github.com/espressif/arduino-esp32"
ARDUINO_ESP32_BRANCH=${ARDUINO_BRANCH}
ARDUINO_ESP32_DIR="${SCRIPT_DIR}/arduino-esp32"

# Install required packages.
sudo apt-get install \
    git wget curl libssl-dev libncurses-dev flex bison gperf python3 \
    python3-pip python3-setuptools python3-serial python3-click python3-cryptography \
    python3-future python3-pyparsing python3-pyelftools cmake ninja-build ccache
sudo pip install --upgrade pip

# For building the unicore / MAC CRC-fixed libraries.
/bin/rm -fR ${LIB_BUILDER_DIR}
git clone --depth 1 ${LIB_BUILDER_REPO} -b ${LIB_BUILDER_BRANCH} ${LIB_BUILDER_DIR}

# The arduino-esp32 repo to patch with the libraries.
/bin/rm -fR ${ARDUINO_ESP32_DIR}
git clone --depth 1 ${ARDUINO_ESP32_REPO} -b ${ARDUINO_ESP32_BRANCH} ${ARDUINO_ESP32_DIR}

# Configure unicore build.
cd ${LIB_BUILDER_DIR}
./tools/update-components.sh
for SDKCONFIG in `find . -type f -name sdkconfig*`; do
    echo "Configure ${SDKCONFIG} for unicore build"
    sed -e 's/.*CONFIG_FREERTOS_UNICORE.*/CONFIG_FREERTOS_UNICORE=y/' -i ${SDKCONFIG}
done

# Install esp-idf.
./tools/install-esp-idf.sh

# Patch esp-idf to ignore MAC CRC errors.
cd ${LIB_BUILDER_DIR}/esp-idf
cat <<EOPATCH | git apply -
diff --git a/components/esp32/system_api.c b/components/esp32/system_api.c
index 7616b4b00..7b9db882b 100644
--- a/components/esp32/system_api.c
+++ b/components/esp32/system_api.c
@@ -115,8 +115,14 @@ esp_err_t esp_efuse_mac_get_default(uint8_t* mac)
                 return ESP_OK;
             }
         } else {
-            ESP_LOGE(TAG, "Base MAC address from BLK0 of EFUSE CRC error, efuse_crc = 0x%02x; calc_crc = 0x%02x", efuse_crc, calc_crc);
-            abort();
+            static bool warned;
+            if (!warned) {
+                warned = true;
+                ESP_LOGW(TAG, "Base MAC address from BLK0 of EFUSE CRC error, efuse_crc = 0x%02x; calc_crc = 0x%02x", efuse_crc, calc_crc);
+                ESP_LOGW(TAG, "On some boards, the stored CRC is actually wrong for the MAC.");
+                ESP_LOGW(TAG, "This firmware was modified to ignore the CRC error and use the MAC as-is.");
+                ESP_LOGW(TAG, "This will have no impact on the network connectivity.");
+            }
         }
     }
     return ESP_OK;
EOPATCH

# Build the unicore library.
cd ${LIB_BUILDER_DIR}
./build.sh

# Patch the arduino-esp32 repo.
cd ${SCRIPT_DIR}
rsync -va ${LIB_BUILDER_DIR}/out/ ${ARDUINO_ESP32_DIR}/

# Just to make sure that no original sdk files remain and that
# I'm only using those from the fresh build. This shouldn't result
# in any updates, but I'm paranoid ;-)
rsync --delete -va ${LIB_BUILDER_DIR}/out/tools/sdk/ ${ARDUINO_ESP32_DIR}/tools/sdk/

echo "----------------------------------------------------------------------------"
echo "Build completed! The unicore / MAC CRC-fixed firmware can be found in:"
echo "${ARDUINO_ESP32_DIR}"
echo "----------------------------------------------------------------------------"
