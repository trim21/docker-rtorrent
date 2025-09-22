FROM debian:13@sha256:833c135acfe9521d7a0035a296076f98c182c542a2b6b5a0fd7063d355d696be AS build-stage

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

FROM debian:13-slim@sha256:c2880112cc5c61e1200c26f106e4123627b49726375eb5846313da9cca117337

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    libssl3 \
    libcurl4 \
    libncursesw6 \
    libstdc++6 \
    lua5.4 \
    ca-certificates \
    && \
    rm -rf /var/lib/apt/lists/*

COPY --from=build-stage /usr/local/bin/rtorrent /usr/local/bin/rtorrent
COPY --from=build-stage /usr/local/lib/libtorrent.so.* /usr/local/lib/
COPY --from=build-stage /usr/local/lib/libtorrent-rasterbar.so.* /usr/local/lib/

RUN ldconfig

ENTRYPOINT ["/usr/local/bin/rtorrent"]
