FROM zephyrprojectrtos/ci:latest

# Arguments
ARG ZEPHYR_CACHE=2.7.0

# ENV Variable
ENV ZEPHYR_WORKDIR=zephyr-project

# Setup zephyr workspace
RUN west init /$ZEPHYR_WORKDIR
RUN cd /$ZEPHYR_WORKDIR && west update && west zephyr-export
RUN echo "export ZEPHYR_BASE=$ZEPHYR_WORKDIR/zephyr" >> /etc/environment

# Overright west config
COPY .west/* /$ZEPHYR_WORKDIR/.west/
RUN echo "caching zephyr v${ZEPHYR_CACHE}"
ADD app-v${ZEPHYR_CACHE} /$ZEPHYR_WORKDIR/app
RUN cd /$ZEPHYR_WORKDIR && west update
RUN rm -rf /$ZEPHYR_WORKDIR/app

# Setting working directory
WORKDIR /$ZEPHYR_WORKDIR

# Setup entrypoint
COPY entrypoint.sh /$ZEPHYR_WORKDIR/entrypoint.sh
ENTRYPOINT [ "./entrypoint.sh" ]
