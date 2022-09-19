#
# Container Image HTTPD
#

FROM golang:1.19.0-alpine3.16 AS base

ARG PROJ_NAME
ARG CFSSL_VERSION

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

RUN apk add --no-cache \
	"ca-certificates" \
	"gcc" \
	"libc-dev"

RUN bins=("cfssl" "cfssljson") \
	&& for bin in "${bins[@]}"; do \
		go install "github.com/cloudflare/cfssl/cmd/${bin}@v${CFSSL_VERSION}"; \
	done

WORKDIR "/tmp/${PROJ_NAME}"

RUN mkdir ".output"

########################################################################################################################

FROM base AS do-tls

COPY "pki/tls-config.json" "./"
COPY "pki/tls-csr.json" "./"

RUN cfssl selfsign -config "tls-config.json" "." "tls-csr.json" \
	| cfssljson -bare ".output/tls" \
	&& mv ".output/tls.csr" ".output/tls-csr.pem" \
	&& mv ".output/tls.pem" ".output/tls-cer.pem" \
	&& cat ".output/tls-cer.pem" > ".output/ca.pem"

########################################################################################################################

FROM scratch AS tls

ARG PROJ_NAME

COPY --from="do-tls" "/tmp/${PROJ_NAME}/.output" "."
