FROM debian:13 AS build-stage

ENV LIBTORRENT_VERSION=0.16.0
ENV RTORRENT_VERSION=0.16.0

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    build-essential \
    libtool \
    ca-certificates \
    curl \
    automake \
    pkg-config \
    libssl-dev \
    libncurses-dev \
    libcurl4-openssl-dev \
    && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /usr/src

RUN curl -sSL https://github.com/rakshasa/libtorrent/archive/refs/tags/v${LIBTORRENT_VERSION}.tar.gz -o libtorrent-${LIBTORRENT_VERSION}.tar.gz
RUN curl -sSL https://github.com/rakshasa/rtorrent/archive/refs/tags/v${RTORRENT_VERSION}.tar.gz -o rtorrent-${RTORRENT_VERSION}.tar.gz


RUN tar xzf libtorrent-${LIBTORRENT_VERSION}.tar.gz && \
    cd libtorrent-${LIBTORRENT_VERSION} && \
    autoreconf -ivf && \
    ./configure && \
    make -j$(nproc) && \
    make install

WORKDIR /usr/src

RUN tar xzf rtorrent-${RTORRENT_VERSION}.tar.gz && \
    cd rtorrent-${RTORRENT_VERSION} && \
    autoreconf -ivf && \
    ./configure --with-xmlrpc-tinyxml2 --with-posix-fallocate && \
    make -j$(nproc) && \
    make install

FROM debian:13-slim

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    libssl3 \
    libcurl4 \
    libncurses6 \
    libstdc++6 \
    ca-certificates \
    libssl-dev \
    && \
    rm -rf /var/lib/apt/lists/*

RUN groupadd -r download && \
    useradd -r -g download -d /home/download -s /sbin/nologin -c "rtorrent user" download

COPY --from=build-stage /usr/local/bin/rtorrent /usr/local/bin/rtorrent
COPY --from=build-stage /usr/local/lib/libtorrent.so.* /usr/local/lib/
COPY --from=build-stage /usr/local/lib/libtorrent-rasterbar.so.* /usr/local/lib/

RUN ldconfig

USER download
WORKDIR /home/download

ENTRYPOINT ["/usr/local/bin/rtorrent"]
