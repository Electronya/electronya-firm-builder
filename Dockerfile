FROM ubuntu:latest

# Arguments
ARG ZEPHYR_CACHE=2.7.0

# TZ setup
ENV TZ=America/Toronto
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

# Upgrade and install nano and wget
RUN apt-get update && apt-get upgrade -y && apt-get install -y nano wget

# Kitware APT repository
RUN wget https://apt.kitware.com/kitware-archive.sh
RUN bash kitware-archive.sh && rm kitware-archive.sh

# Install dependencies
RUN apt-get install -y --no-install-recommends git cmake ninja-build gperf \
    ccache dfu-util device-tree-compiler wget udev \
    python3-dev python3-pip python3-setuptools python3-tk python3-wheel \
    xz-utils file make gcc gcc-multilib g++-multilib libsdl2-dev libmagic1

# Validate dependencies installation
RUN cmake --version
RUN python3 --version
RUN dtc --version

# install west
RUN pip3 install -U west

# Setup zephyr workspace
RUN west init /zephyr-project
RUN cd /zephyr-project && west update && west zephyr-export
# RUN cp -r /home/user/.cmake/packages/Zephyr-sdk /root/.cmake/packages/
RUN pip3 install -r /zephyr-project/zephyr/scripts/requirements.txt
# RUN source /zephyr-project/zephyr/zephyr-env.sh

# Setup zephyr SDK
RUN cd / && wget https://github.com/zephyrproject-rtos/sdk-ng/releases/download/v0.16.5/zephyr-sdk-0.16.5_linux-x86_64.tar.xz
RUN wget -O - https://github.com/zephyrproject-rtos/sdk-ng/releases/download/v0.16.5/sha256.sum | shasum --check --ignore-missing
RUN tar xvf zephyr-sdk-0.16.5_linux-x86_64.tar.xz -C /opt/
RUN cd /opt/zephyr-sdk-0.16.5 && ./setup.sh -t x86_64-zephyr-elf -c -h
RUN cp ./sysroots/x86_64-pokysdk-linux/usr/share/openocd/contrib/60-openocd.rules /etc/udev/rules.d
# RUN udevadm control --reload
RUN cd / && rm zephyr-sdk-0.16.5_linux-x86_64.tar.xz

# Overright west config
COPY .west/* /zephyr-project/.west/
RUN echo "caching zephyr v${ZEPHYR_CACHE}"
ADD app-v${ZEPHYR_CACHE} /zephyr-project/app
RUN cd /zephyr-project && west update
RUN rm -rf /zephyr-project/app

# Setting working directory
WORKDIR /zephyr-project

# Setup entrypoint
COPY entrypoint.sh /zephyr-project/entrypoint.sh
ENTRYPOINT [ "/zephyr-project/entrypoint.sh" ]
CMD ["prod"]
