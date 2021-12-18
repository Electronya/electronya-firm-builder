# electronya-firm-builder
Electronya Firmware Builder Image

This container is meant to be use to build firmwares. The image is based on zephyr-ci image and contains the cached version of zephyr RTOS idicated by the image tag.

## Building the image
To build the image, simply use the following commands:
```
git clone git@github.com:Electronya/electronya-firm-builder.git
cd electronya-firm-builder
docker build --build-arg ZEPHYR_CACHE=<version-to-cache>
```
Where ```version-to-cache``` is the version of zephyr to be cached in the image.
