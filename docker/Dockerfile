# zigbeemqtt

# docker build . -t zigbee2mqtt
# docker run --privileged  -ti --rm -e TZ=Europe/Amsterdam -v /dev/ttyACM0:/dev/ttyACM0 zigbee2mqtt


ARG ARCH=arm32v6
ARG VERSION=1.13.0

FROM "koenkk/zigbee2mqtt:${VERSION}" as zigbee2mqtt

ARG ARCH
ARG VERSION
ARG MYVERSION=jose0
ARG TZ=Europe/Amsterdam
ARG CONFIGDIR=/config
ARG YQ=https://github.com/mikefarah/yq/releases/download/3.3.0/yq_linux_amd64

LABEL org.label-schema.description="Zigbee to MQTT bridge."
LABEL org.label-schema.name="rpi-zigbee2mqtt"
LABEL org.label-schema.version="${VERSION}-${MYVERSION}"
LABEL org.label-schema.usage="/README.md"
LABEL org.label-schema.url="https://hub.docker.com/r/jriguera/rpi-zigbee2mqtt"
LABEL org.label-schema.vcs-url="https://github.com/jriguera/docker-rpi-zigbee2mqtt"
LABEL maintainer="Jose Riguera <jriguera@gmail.com>"
LABEL architecture="${ARCH}"

ENV LANG=en_US.utf8
ENV LC_ALL=C.UTF-8
ENV CONFIGDIR="${CONFIGDIR}"

RUN set -xe                                                                 && \
    apk -U upgrade                                                          && \
    # Installing Alpine packages
    apk add --no-cache \
        ca-certificates \
        pwgen \
        tzdata \
        socat \
        bash \
                                                                            && \
    wget -qO /usr/bin/yq ${YQ}                                              && \
    chmod a+x /usr/bin/yq                                                   && \
    # Timezone
    cp "/usr/share/zoneinfo/${TZ}" /etc/localtime                           && \
    echo "${TZ}" > /etc/timezone                                            && \
    # clean up
    rm -rf /tmp/* /var/tmp/* /var/cache/apk/* /var/cache/distfiles/*

COPY *.sh /usr/local/bin/

RUN set -xe                                                                 && \
    chmod a+x /usr/local/bin/*                                              && \
    rm -f /usr/local/bin/docker-entrypoint.sh                               && \
    ln -s /usr/local/bin/zigbee2mqtt.sh /usr/local/bin/docker-entrypoint.sh && \
    ln -s /usr/local/bin/zigbee2mqtt.sh /docker-entrypoint.sh               && \
    ln -s /usr/local/bin/zigbee2mqtt.sh /run.sh                             && \
    mkdir -p /docker-entrypoint-initdb.d                                    && \
    mkdir -p "${CONFIGDIR}"                                                 && \
    rm -rf /app/data && ln -sf "${CONFIGDIR}" /app/data

WORKDIR "/app"
VOLUME "${CONFIGDIR}"
ENTRYPOINT ["/run.sh"]
CMD ["npm", "start"]

