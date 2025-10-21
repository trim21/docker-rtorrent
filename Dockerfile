FROM debian:13-slim@sha256:66b37a5078a77098bfc80175fb5eb881a3196809242fd295b25502854e12cbec AS build-stage

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
    ./configure --disable-shared --enable-static && \
    make -j$(nproc) && \
    make install

WORKDIR /usr/src

RUN tar xzf rtorrent-${RTORRENT_VERSION}.tar.gz && \
    cd rtorrent-${RTORRENT_VERSION} && \
    autoreconf -ivf && \
    ./configure --with-xmlrpc-tinyxml2 --with-posix-fallocate --with-lua && \
    make -j$(nproc) && \
    make install

FROM debian:13-slim@sha256:66b37a5078a77098bfc80175fb5eb881a3196809242fd295b25502854e12cbec

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

ENTRYPOINT ["/usr/local/bin/rtorrent"]
