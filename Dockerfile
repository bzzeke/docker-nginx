FROM alpine
WORKDIR /app
VOLUME ["/etc/ssl/acme", "/etc/acme"]

USER root

RUN apk update
RUN apk add --no-cache nginx nginx-mod-stream bash
RUN mkdir -p /run/nginx
RUN mkdir -p /etc/ssl/le

ADD config /
ADD app /app

EXPOSE 80 443

CMD ["/app/run.sh"]
