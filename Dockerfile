FROM zephyrprojectrtos/ci:latest

# Arguments
ARG ZEPHYR_CACHE=2.7.0

#install nano
RUN apt update && apt install nano

# Setup zephyr workspace
RUN west init /zephyr-project
RUN cd /zephyr-project && west update && west zephyr-export
RUN cp -r /home/user/.cmake/packages/Zephyr-sdk /root/.cmake/packages/
RUN pip3 install --user -r /zephyr-project/zephyr/scripts/requirements.txt
RUN source /zephyr-project/zephyr/zephyr-env.sh

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
