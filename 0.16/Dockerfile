FROM frolvlad/alpine-glibc:alpine-3.7

MAINTAINER https://github.com/dtandersen/docker_factorio_server

ARG USER=factorio
ARG GROUP=factorio
ARG PUID=845
ARG PGID=845

ENV PORT=34197 \
    RCON_PORT=27015 \
    VERSION=0.16.30 \
    SHA1=7ceac7d3cfee2c301707e2622400d2c7bc6f2e8c \
    SAVES=/factorio/saves \
    CONFIG=/factorio/config \
    MODS=/factorio/mods \
    SCENARIOS=/factorio/scenarios \
    ENTRYPOINTS=/factorio/entrypoints

RUN mkdir -p /opt /factorio && \
    apk add --update --no-cache pwgen && \
    apk add --update --no-cache --virtual .build-deps curl && \
    curl -sSL https://www.factorio.com/get-download/$VERSION/headless/linux64 \
        -o /tmp/factorio_headless_x64_$VERSION.tar.xz && \
    echo "$SHA1  /tmp/factorio_headless_x64_$VERSION.tar.xz" | sha1sum -c && \
    tar xf /tmp/factorio_headless_x64_$VERSION.tar.xz --directory /opt && \
    chmod ugo=rwx /opt/factorio && \
    rm /tmp/factorio_headless_x64_$VERSION.tar.xz && \
    ln -s -f $SAVES /opt/factorio/saves && \
    ln -s -f $MODS /opt/factorio/mods && \
    ln -s -f $SCENARIOS /opt/factorio/scenarios && \
    ln -s -f $ENTRYPOINTS /opt/factorio/entrypoints && \
    apk del .build-deps && \
    addgroup -g $PGID -S $GROUP && \
    adduser -u $PUID -G $GROUP -s /bin/sh -SDH $USER && \
    chown -R $USER:$GROUP /opt/factorio /factorio

VOLUME /factorio

EXPOSE $PORT/udp $RCON_PORT/tcp

COPY ./docker-entrypoint.sh /
COPY ./scenario2map.sh /factorio/entrypoints
COPY ./scenario.sh /factorio/entrypoints

#symbolic link the default entrypoint to the entrypoints directory so it can be inspected and copied to new entrypoints
#RUN ln -s -f /docker-entrypoint.sh $ENTRYPOINTS/docker-entrypoint.sh

USER $USER

ENTRYPOINT ["/docker-entrypoint.sh"]
