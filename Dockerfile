ARG LITESTREAM_TAG

# Build container
FROM --platform=linux/arm64 litestream/litestream:${LITESTREAM_TAG} AS buildstage-arm64
# Build container
FROM --platform=linux/armhf litestream/litestream:${LITESTREAM_TAG} AS buildstage-armhf

# Build container
FROM golang:alpine AS buildstage-amd64

ARG LITESTREAM_TAG

RUN mkdir -p /root-layer/litestream
WORKDIR /src

RUN apk --no-cache add git build-base curl jq

RUN git -c advice.detachedHead=false clone https://github.com/benbjohnson/litestream --depth=1 --branch ${LITESTREAM_TAG} .

RUN make dist-linux
RUN mv ./dist/litestream /root-layer/litestream/litestream-amd64

COPY root/ /root-layer/

## Single layer deployed image ##
FROM scratch

LABEL maintainer="Spunkie"

# Add files from buildstages
COPY --from=buildstage-amd64 /root-layer/ /
COPY --from=buildstage-arm64 /usr/local/bin/litestream /litestream/litestream-arm64
COPY --from=buildstage-armhf /usr/local/bin/litestream /litestream/litestream-armhf