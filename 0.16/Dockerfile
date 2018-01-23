FROM frolvlad/alpine-glibc:alpine-3.7

MAINTAINER https://github.com/dtandersen/docker_factorio_server

ARG USER=factorio
ARG GROUP=factorio
ARG PUID=845
ARG PGID=845

ENV PORT=34197 \
    RCON_PORT=27015 \
    VERSION=0.16.18 \
    SHA1=add8b48f44a24d4ae474843f57b66cfc97749d3d

RUN mkdir -p /opt /factorio && \
    apk add --update --no-cache pwgen && \
    apk add --update --no-cache --virtual .build-deps curl && \
    curl -sSL https://www.factorio.com/get-download/$VERSION/headless/linux64 \
        -o /tmp/factorio_headless_x64_$VERSION.tar.xz && \
    echo "$SHA1  /tmp/factorio_headless_x64_$VERSION.tar.xz" | sha1sum -c && \
    tar xf /tmp/factorio_headless_x64_$VERSION.tar.xz --directory /opt && \
    chmod ugo=rwx /opt/factorio && \
    rm /tmp/factorio_headless_x64_$VERSION.tar.xz && \
    ln -s /factorio/saves /opt/factorio/saves && \
    ln -s /factorio/mods /opt/factorio/mods && \
    apk del .build-deps && \
    addgroup -g $PGID -S $GROUP && \
    adduser -u $PUID -G $USER -s /bin/sh -SDH $GROUP && \
    chown -R $USER:$GROUP /opt/factorio /factorio

VOLUME /factorio

EXPOSE $PORT/udp $RCON_PORT/tcp

COPY ./docker-entrypoint.sh /

USER $USER

ENTRYPOINT ["/docker-entrypoint.sh"]
