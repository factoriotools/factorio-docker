FROM frolvlad/alpine-glibc:alpine-3.5

MAINTAINER https://github.com/dtandersen/docker_factorio_server

ENV PORT=34197 \
    VERSION=0.15.10 \
    SHA1=2e11b3a9dd2e2a0a5831032325615c37a65ed414

RUN mkdir /opt && \
    apk add --update --no-cache tini pwgen && \
    apk add --update --no-cache --virtual .build-deps curl && \
    curl -sSL https://www.factorio.com/get-download/$VERSION/headless/linux64 \
        -o /tmp/factorio_headless_x64_$VERSION.tar.xz && \
    echo "$SHA1  /tmp/factorio_headless_x64_$VERSION.tar.xz" | sha1sum -c && \
    tar xf /tmp/factorio_headless_x64_$VERSION.tar.xz --directory /opt && \
    rm /tmp/factorio_headless_x64_$VERSION.tar.xz && \
    ln -s /factorio/saves /opt/factorio/saves && \
    ln -s /factorio/mods /opt/factorio/mods && \
    apk del .build-deps

VOLUME /factorio

EXPOSE $PORT/udp 27015/tcp

COPY ./docker-entrypoint.sh /

ENTRYPOINT ["/sbin/tini", "--"]
CMD ["/docker-entrypoint.sh"]
