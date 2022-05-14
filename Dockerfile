# Build container
FROM golang:alpine AS buildstage

ARG LITESTREAM_TAG

RUN mkdir -p /root-layer/litestream
WORKDIR /src

RUN apk --no-cache add git build-base curl jq

RUN \
  if [ -z "${LITESTREAM_TAG}" ]; then \
    curl -s https://api.github.com/repos/benbjohnson/litestream/releases/latest \
      | jq -rc ".tag_name" \
      | xargs -I TAG sh -c 'git -c advice.detachedHead=false clone https://github.com/benbjohnson/litestream --depth=1 --branch TAG .'; \
  else \
    git -c advice.detachedHead=false clone https://github.com/benbjohnson/litestream --depth=1 --branch ${LITESTREAM_TAG} .; \
  fi

RUN make dist-linux
RUN mv ./dist/litestream /root-layer/litestream/litestream-amd64

RUN make dist-linux-arm64
RUN mv ./dist/litestream-linux-arm64 /root-layer/litestream/litestream-arm64

RUN make dist-linux-arm
RUN mv ./dist/litestream-linux-arm /root-layer/litestream/litestream-armhf

COPY root/ /root-layer/

## Single layer deployed image ##
FROM scratch

LABEL maintainer="Spunkie"

# Add files from buildstage
COPY --from=buildstage /root-layer/ /
