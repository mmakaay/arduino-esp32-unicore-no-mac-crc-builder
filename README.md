# arduino-esp32-unicore-no-mac-crc-builder

This repository contains code that is used to build the platform
packages as distributed through the GitHub repository:

  https://github.com/mmakaay/arduino-esp32-unicore-no-mac-crc

It provides a version of the arduino-esp32 platform packages with
the following changes compared to the regular distribution:

## Unicore support

The distributed arduino-esp32 package only supports dual core ESP32
chips. If you compile firmware using that package for a single core
variant of the chip, the device will end up in a boot loop, stating
the error:

```
E (459) cpu_start: Running on single core chip, but application is built with dual core support.
E (459) cpu_start: Please enable CONFIG_FREERTOS_UNICORE option in menuconfig.
```

Enabling the CONFIG_FREERTOS_UNICORE build option is exacly what the
build code from this repo does. This makes the resulting arduino-esp32
compatible with single core ESP32 chips.


## MAC CRC fix

The default MAC address for a device is read from EFUSE (`MAC_FACTORY`),
together with a CRC for this MAC address (`MAC_FACTORY_CRC`).

On some devices, a wrong CRC was burnt into EFUSE, causing the firmware
to end up in a boot loop, stating the error:

```
Base MAC address from BLK0 of EFUSE CRC error
```

This firmware downgrades this error to a warning, and accepts the MAC
address that was read from EFUSE as-is. This makes it possible to boot
these erratic devices.

