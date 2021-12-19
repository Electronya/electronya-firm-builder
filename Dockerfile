FROM zephyrprojectrtos/ci:latest

# Arguments
ARG ZEPHYR_CACHE=2.7.0

# ENV Variable
ENV ZEPHYR_WORKDIR=zephyr-project

# Setup zephyr workspace
RUN west init /$ZEPHYR_WORKDIR
RUN cd /$ZEPHYR_WORKDIR && west update && west zephyr-export
RUN cp -rf /home/user/.cmake/packages/Zephyr-sdk /root/.cmake/packages/Zephyr-sdk
RUN pip3 install --user -r /$ZEPHYR_WORKDIR/zephyr/scripts/requirements.txt

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
CMD ["prod"]
