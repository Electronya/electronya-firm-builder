FROM zephyrprojectrtos/ci:latest

# Arguments
ARG ZEPHYR_CACHE=2.7.0

# Setup zephyr workspace
RUN west init /zephyr-project
RUN cd /zephyr-project && west update && west zephyr-export
RUN pip3 install --user -r /zephyr-project/zephyr/scripts/requirements.txt

# Overright west config
COPY .west/* /zephyr-project/.west/
ADD app-v${ZEPHYR_CACHE} /zephyr-project/app
RUN cd /zephyr-project && west update
RUN rm -rf /zephyr-project/app

# Setup input and output volumes
RUN mkdir /builds
RUN mkdir /cache
VOLUME [ "/builds", "/cache" ]
