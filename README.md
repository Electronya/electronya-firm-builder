# electronya-firm-builder
Electronya Firmware Builder Image

This container is meant to be use to build firmware. The image is based on zephyr-ci image and contains the cached version of zephyr RTOS indicated by the image tag.

## Building the image
To build the image, simply use the following commands:
```
git clone git@github.com:Electronya/electronya-firm-builder.git
cd electronya-firm-builder
docker build --build-arg ZEPHYR_CACHE=<version-to-cache>
```
Where:
  - ```<version-to-cache>``` is the version of zephyr to be cached in the image.

## Usage
To build firmware, use the following command from the root of the firmware to build:
```
docker run --name firmware-builder --rm -it \
  --privileged -v /dev/bus/usb:/dev/bus/usb \
  -v "${PWD}:/github/workspace" \
  judebake/electronya-firm-builder:<zephyr-version> <build-mode>
```
Where:
  - ```<build-mode>``` is one of the following build mode:
    - ```config```: run the configuration tool (currently configuration is not saved).
    - ```prod```: build the firmware in production mode (logger level = info).
    - ```dev```: build, flash, and run the firmware in development mode (logger level = debug).
    - ```debug```: build, flash the firmware (logger level = debug), and launch gdb for debugging.
    - ```qemu```: build and run the firmware in emulation mode (no hardware is emulated).
    - ```test```: run the firmware unit test cases (in emulation mode).
  - ```<zephyr-version>```: is the version of zephyr to build against. Currently supported version:
    - 2.7.0, 2.7.1, 2.7.3, 3.2.0, 3.3.0
