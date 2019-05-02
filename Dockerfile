#
# Builder
#
FROM abiosoft/caddy:builder as builder

ARG GOARCH="arm"
ARG GOARM="7"

ARG version="1.0.0"
ARG plugins="prometheus,filebrowser,cors,expires,cache,git,cloudflare,proxyprotocol,realip,ipfilter"

# process wrapper
RUN go get -v github.com/abiosoft/parent

RUN VERSION=${version} PLUGINS=${plugins} GOARCH=${GOARCH} GOARM=${GOARM} /bin/sh /usr/bin/builder.sh

#
# Final stage
#
FROM balenalib/raspberrypi3:stretch

RUN [ "cross-build-start" ]

LABEL maintainer "Matthew Schick <matthew.schick@gmail.com>"

ARG version="1.0.0"
LABEL caddy_version="$version"

# Let's Encrypt Agreement
ENV ACME_AGREE="true"

RUN apk add --no-cache openssh-client git

# install caddy
COPY --from=builder /install/caddy /usr/bin/caddy

# validate install
RUN /usr/bin/caddy -version
RUN /usr/bin/caddy -plugins

RUN [ "cross-build-end" ]

EXPOSE 80 443
VOLUME /root/.caddy /srv
WORKDIR /srv

# install process wrapper
COPY --from=builder /go/bin/parent /bin/parent

ENTRYPOINT ["/bin/parent", "caddy"]
CMD ["--conf", "/etc/Caddyfile", "--log", "stdout", "--agree=$ACME_AGREE"]
