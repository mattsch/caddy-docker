#
# Builder
#
FROM abiosoft/caddy:builder as builder

ARG version="0.11.5"
ARG plugins="git,cloudflare,proxyprotocol,prometheus"

RUN VERSION=${version} PLUGINS=${plugins} /bin/sh /usr/bin/builder.sh

#
# Final stage
#
FROM alpine:3.9
LABEL maintainer "Matthew Schick <matthew.schick@gmail.com>"

ARG version="0.11.5"
LABEL caddy_version="$version"

RUN apk add --no-cache openssh-client git

# install caddy
COPY --from=builder /install/caddy /usr/bin/caddy

# validate install
RUN /usr/bin/caddy -version
RUN /usr/bin/caddy -plugins

EXPOSE 80 443
VOLUME /root/.caddy /srv

ENTRYPOINT ["caddy"]
CMD ["-conf", "/etc/Caddyfile", "-log", "stdout", "-agree"]
