FROM voidlinux/voidlinux-musl:latest
MAINTAINER Imran Khan <imrankhan@teknik.io>

RUN echo repository=https://void:void@void.repo.defmacro.me/musl > /etc/xbps.d/02-my-remote.conf \
    && yes Y | xbps-install -Syu curl gnuplot jq make mksh tab txr \
    && rm -rf /var/db/xbps/ /var/cache/xbps/

WORKDIR /dashboard/

CMD ./run.sh clean ; make
