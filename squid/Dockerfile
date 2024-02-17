FROM ubuntu:23.10 as build

ENV SQUID_VERSION=6.7 \
    SQUID_CACHE_DIR=/var/spool/squid \
    SQUID_LOG_DIR=/var/log/squid \
    SQUID_DATA_DIR=/var/lib/squid \
    SQUID_USER=proxy

RUN \
  sed -i~ 's!http://archive.ubuntu.com/ubuntu/!mirror://mirrors.ubuntu.com/mirrors.txt!' /etc/apt/sources.list && \
  apt-get update && \
  apt-get upgrade --no-install-recommends -y && \
  DEBIAN_FRONTEND=noninteractive apt-get install -y \
    autoconf \
    autoconf-archive \
    automake \
    bzip2 \
    ca-certificates \
    ccache \
    clang \
    curl \
    ed \
    g++ \
    git \
    gnutls-bin \
    icecc \
    libcap-dev \
    libcppunit-dev \
    libexpat-dev \
    libgnutls28-dev \
    libltdl-dev \
    libssl-dev \
    libtdb-dev \
    libtool \
    libtool-bin \
    libxml2-dev \
    make \
    nettle-dev \
    pandoc \
    pkg-config \
    po4a \
    translate-toolkit \
    wget \
    xz-utils \
  && \
  apt-get autoremove -y && \
  apt-get clean -y

RUN wget https://www.squid-cache.org/Versions/v6/squid-${SQUID_VERSION}.tar.gz
RUN tar xzf squid-${SQUID_VERSION}.tar.gz
RUN cd squid-${SQUID_VERSION} && \
    ./configure --prefix=/usr \
                --with-openssl \
                --enable-icap-client \
                --enable-ssl-crtd \
                --localstatedir=/var \
                --libexecdir=${prefix}/lib/squid \
                --datadir=${prefix}/share/squid \
                --sysconfdir=/etc/squid \
                --with-default-user=${SQUID_USER} \
                --with-logdir=/var/log/squid \
                --with-pidfile=/var/run/squid.pid \
                && \
    make && \
    make check && \
    make install

COPY entrypoint.sh /sbin/entrypoint.sh
COPY null-auth.sh /sbin/null-auth.sh
RUN chmod 755 /sbin/entrypoint.sh

EXPOSE 3128/tcp
ENTRYPOINT ["/sbin/entrypoint.sh"]
