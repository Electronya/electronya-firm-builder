FROM zephyrprojectrtos/ci:latest

# Arguments
ARG ZEPHYR_CACHE=2.7.0

# Setup zephyr workspace
RUN west init /zephyr-workdir
RUN cd /zephyr-workdir && west update && west zephyr-export

# Overright west config
COPY .west/* /zephyr-workdir/.west/
RUN echo "caching zephyr v${ZEPHYR_CACHE}"
ADD app-v${ZEPHYR_CACHE} /zephyr-workdir/app
RUN cd /zephyr-workdir && west update
RUN rm -rf /zephyr-workdir/app

# Setting working directory
WORKDIR /zephyr-workdir

# Setup entrypoint
COPY entrypoint.sh /zephyr-workdir/entrypoint.sh
ENTRYPOINT [ "./entrypoint.sh" ]
