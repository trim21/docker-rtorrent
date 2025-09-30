FROM debian:13@sha256:fd8f5a1df07b5195613e4b9a0b6a947d3772a151b81975db27d47f093f60c6e6 AS build-stage

ENV LIBTORRENT_VERSION=0.15.7
ENV RTORRENT_VERSION=0.15.7

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
    liblua5.4-dev \
    lua5.4 \
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
    ./configure --with-xmlrpc-tinyxml2 --with-posix-fallocate --with-lua && \
    make -j$(nproc) && \
    make install

FROM debian:13-slim@sha256:fb6a168c24c6bb598f73c1ec6270c692eb2379b54f2936425996b7ddddb8a720

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    libssl3 \
    libcurl4 \
    libncursesw6 \
    libstdc++6 \
    liblua5.4 \
    ca-certificates \
    && \
    rm -rf /var/lib/apt/lists/*

COPY --from=build-stage /usr/local/bin/rtorrent /usr/local/bin/rtorrent
COPY --from=build-stage /usr/local/lib/libtorrent.so.* /usr/local/lib/
COPY --from=build-stage /usr/local/lib/libtorrent-rasterbar.so.* /usr/local/lib/

RUN ldconfig

ENTRYPOINT ["/usr/local/bin/rtorrent"]
