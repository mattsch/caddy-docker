#
# Builder
#
FROM abiosoft/caddy:builder as builder

env GOARCH="arm" GOARM="7" GOOS="linux"

ARG VERSION="1.0.3"
ARG PLUGINS="prometheus,cors,expires,cache,git,cloudflare,proxyprotocol,realip"

# process wrapper
RUN go get -v github.com/abiosoft/parent

COPY builder.sh /usr/bin/builder.sh

RUN /usr/bin/builder.sh

#
# Final stage
#
FROM balenalib/raspberrypi3-alpine:3.10

RUN [ "cross-build-start" ]

LABEL maintainer "Matthew Schick <matthew.schick@gmail.com>"

ARG version="1.0.3"
LABEL caddy_version="$version"

# Let's Encrypt Agreement
ENV ACME_AGREE="true"

RUN apk add --no-cache openssh-client git

# install caddy and process wrapper
COPY --from=builder /install/caddy /usr/bin/caddy
COPY --from=builder /go/bin/linux_arm/parent /bin/parent

# validate install
RUN /usr/bin/caddy -version && \
    /usr/bin/caddy -plugins

RUN [ "cross-build-end" ]

EXPOSE 80 443
VOLUME /root/.caddy /srv
WORKDIR /srv

ENTRYPOINT ["/bin/parent", "caddy"]
CMD ["--conf", "/etc/Caddyfile", "--log", "stdout", "--agree=$ACME_AGREE"]
