#
# Container Image HTTPD
#

FROM alpine:3.16.2

ARG PROJ_NAME
ARG PROJ_VERSION
ARG PROJ_BUILD_NUM
ARG PROJ_BUILD_DATE
ARG PROJ_REPO

LABEL org.opencontainers.image.authors="V10 Solutions"
LABEL org.opencontainers.image.title="${PROJ_NAME}"
LABEL org.opencontainers.image.version="${PROJ_VERSION}"
LABEL org.opencontainers.image.revision="${PROJ_BUILD_NUM}"
LABEL org.opencontainers.image.created="${PROJ_BUILD_DATE}"
LABEL org.opencontainers.image.description="Container image for HTTPD"
LABEL org.opencontainers.image.source="${PROJ_REPO}"

RUN apk update \
	&& apk add --no-cache "shadow" "bash" \
	&& usermod -s "$(command -v "bash")" "root"

SHELL [ \
	"bash", \
	"--noprofile", \
	"--norc", \
	"-o", "errexit", \
	"-o", "nounset", \
	"-o", "pipefail", \
	"-c" \
]

ENV LANG "C.UTF-8"
ENV LC_ALL "${LANG}"
ENV LD_LIBRARY_PATH "${LD_LIBRARY_PATH}:/usr/local/lib/httpd"

RUN apk add --no-cache \
	"ca-certificates" \
	"curl" \
	"apr-dev" \
	"apr-util-dev" \
	"curl-dev" \
	"zlib-dev" \
	"pcre2-dev" \
	"argon2-dev" \
	"brotli-dev" \
	"lua5.1-dev" \
	"jansson-dev" \
	"libxml2-dev" \
	"nghttp2-dev" \
	"openssl-dev"

RUN apk add --no-cache -t "build-deps" \
	"make" \
	"patch" \
	"linux-headers" \
	"gcc" \
	"g++" \
	"pkgconf"

RUN groupadd -r -g "480" "httpd" \
	&& useradd \
		-r \
		-m \
		-s "$(command -v "nologin")" \
		-g "httpd" \
		-c "HTTPD" \
		-u "480" \
		"httpd"

WORKDIR "/tmp"

COPY "patches" "patches"

COPY "config.layout" "./"

RUN curl -L -f -o "httpd.tar.gz" "http://archive.apache.org/dist/httpd/httpd-${PROJ_VERSION}.tar.gz" \
	&& mkdir "httpd" \
	&& tar -x -f "httpd.tar.gz" -C "httpd" --strip-components "1" \
	&& pushd "httpd" \
	&& find "../patches" \
		-mindepth "1" \
		-type "f" \
		-iname "*.patch" \
		-exec bash --noprofile --norc -c "patch -p \"1\" < \"{}\"" ";" \
	&& mv "../config.layout" "./" \
	&& ./configure \
		--prefix="/usr/local" \
		--libdir="/usr/local/lib/httpd" \
		--libexecdir="/usr/local/libexec/httpd" \
		--sysconfdir="/usr/local/etc/httpd" \
		--datarootdir="/usr/local/share/httpd" \
		--sharedstatedir="/usr/local/com/httpd" \
		--with-z \
		--with-ssl \
		--with-lua="/usr" \
		--with-curl \
		--with-pcre \
		--with-brotli \
		--with-libxml2 \
		--with-mpm="prefork" \
		--with-apr="$(command -v "apr-1-config")" \
		--with-apr-util="$(command -v "apu-1-config")" \
		--enable-layout="Alpine" \
		--enable-md \
		--enable-cgi \
		--enable-cgid \
		--enable-sed \
		--enable-substitute \
		--enable-ssl \
		--enable-dbd \
		--enable-data \
		--enable-info \
		--enable-lua \
		--enable-luajit \
		--enable-unixd \
		--enable-brotli \
		--enable-include \
		--enable-deflate \
		--enable-rewrite \
		--enable-expires \
		--enable-ratelimit \
		--enable-watchdog \
		--enable-mime-magic \
		--enable-charset-lite \
		--enable-logio \
		--enable-log-debug \
		--enable-log-forensic \
		--enable-dav \
		--enable-dav-fs \
		--enable-dav-lock \
		--enable-authn-dbm \
		--enable-authn-dbd \
		--enable-authn-anon \
		--enable-authn-socache \
		--enable-authz-dbm \
		--enable-authz-dbd \
		--enable-authz-owner \
		--enable-auth-form \
		--enable-auth-digest \
		--enable-ldap \
		--enable-authnz-fcgi \
		--enable-authnz-ldap \
		--enable-allowmethods \
		--enable-cache \
		--enable-mem-cache \
		--enable-disk-cache \
		--enable-file-cache \
		--enable-so \
		--enable-socache-dbm \
		--enable-socache-shmcb \
		--enable-socache-redis \
		--enable-socache-memcache \
		--enable-session \
		--enable-session-cookie \
		--enable-session-crypto \
		--enable-session-dbd \
		--enable-http \
		--enable-http2 \
		--enable-proxy-http2 \
		--enable-proxy \
		--enable-proxy-ajp \
		--enable-proxy-ftp \
		--enable-proxy-http \
		--enable-proxy-fcgi \
		--enable-proxy-scgi \
		--enable-proxy-uwsgi \
		--enable-proxy-fdpass \
		--enable-proxy-hcheck \
		--enable-proxy-connect \
		--enable-proxy-express \
		--enable-proxy-wstunnel \
		--enable-proxy-balancer \
		--enable-exception-hook \
		--enable-mods-shared="all" \
		--enable-mpms-shared="all" \
	&& make \
	&& make "install" \
	&& ldconfig "${LD_LIBRARY_PATH}" \
	&& popd \
	&& rm -r -f "httpd" \
	&& rm "httpd.tar.gz" \
	&& rm -r -f "patches"

WORKDIR "/usr/local"

RUN mkdir -p "etc/httpd" "lib/httpd" "libexec/httpd" "share/httpd" \
	&& folders=("com/httpd" "var/lib/httpd" "var/run/httpd" "var/log/httpd" "var/cache/httpd") \
	&& for folder in "${folders[@]}"; do \
		mkdir -p "${folder}" \
		&& chmod "700" "${folder}" \
		&& chown -R "480":"480" "${folder}"; \
	done

WORKDIR "/"

RUN apk del "build-deps"
