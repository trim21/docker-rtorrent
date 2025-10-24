# syntax=docker/dockerfile:1

ARG LIBTORRENT_VERSION=v0.15.7
ARG RTORRENT_VERSION=v0.15.7
ARG EXTRA_CONFIGURE_ARGS=""
ARG LIBTORRENT_CONFIGURE_ARGS=""
ARG RTORRENT_CONFIGURE_ARGS=""

FROM debian:13-slim@sha256:66b37a5078a77098bfc80175fb5eb881a3196809242fd295b25502854e12cbec AS base

RUN apt-get update

FROM base AS src
ARG LIBTORRENT_VERSION
ARG RTORRENT_VERSION
ARG LIBTORRENT_CONFIGURE_ARGS
ARG RTORRENT_CONFIGURE_ARGS

RUN apt-get install -y --no-install-recommends \
    git \
    ca-certificates

WORKDIR /usr/src

RUN git clone https://github.com/rakshasa/libtorrent /libtorrent --depth=1 --branch ${LIBTORRENT_VERSION}
RUN git clone https://github.com/rakshasa/rtorrent /rtorrent --depth=1 --branch ${LIBTORRENT_VERSION}

FROM base AS build-stage
ARG EXTRA_CONFIGURE_ARGS


RUN apt-get update -y && \
    apt-get install -y --no-install-recommends \
        build-essential \
        libtool \
        automake \
        libcurl4-openssl-dev \
        libncurses-dev \
        liblua5.4-dev \
        zlib1g-dev \
        lua5.4

COPY --from=src /libtorrent /libtorrent/
COPY --from=src /rtorrent /rtorrent/

WORKDIR /libtorrent/

RUN autoreconf -ivf && \
    ./configure --enable-aligned --disable-shared --enable-static ${LIBTORRENT_CONFIGURE_ARGS} ${EXTRA_CONFIGURE_ARGS} && \
    make -j$(nproc) CXXFLAGS="-w -O3 -flto -Werror=odr -Werror=lto-type-mismatch -Werror=strict-aliasing" && \
    make install

WORKDIR /rtorrent/

RUN cd /rtorrent/ && \
    autoreconf -ivf && \
    ./configure --with-ncurses --without-ncursesw --with-xmlrpc-tinyxml2 --with-posix-fallocate ${RTORRENT_CONFIGURE_ARGS} ${EXTRA_CONFIGURE_ARGS} && \
    make -j$(nproc) CXXFLAGS="-w -O3 -flto -Werror=odr -Werror=lto-type-mismatch -Werror=strict-aliasing" && \
    make install

#
FROM base
#
RUN apt-get update -y && \
    apt-get install -y --no-install-recommends \
    libssl3 \
    libcurl4t64 \
    libgcc-s1 \
    libncurses6 \
    libstdc++6 \
    liblua5.4 \
    zlib1g \
    ca-certificates \
    && \
    rm -rf /var/lib/apt/lists/*

COPY --from=build-stage /usr/local/bin/rtorrent /usr/local/bin/rtorrent

ENTRYPOINT ["/usr/local/bin/rtorrent"]
