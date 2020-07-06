# Original credit:

FROM alpine:latest

LABEL maintainer="YuXiao(xiao.950901@gmail.com)"

# Needed by scripts
ENV OVPN_DIR /etc/openvpn
ENV OVPN_PKI_DIR ${OVPN_DIR}/pki

RUN \
  echo 'http://dl-cdn.alpinelinux.org/alpine/edge/testing/' >> /etc/apk/repositories && \
  sed -i 's/dl-cdn.alpinelinux.org/mirrors.aliyun.com/g' /etc/apk/repositories && \
  apk update && apk upgrade && \
  apk add -u bash iptables easy-rsa openvpn openssl openvpn-auth-pam openvpn-auth-ldap && \
  ln -s /usr/share/easy-rsa/easyrsa /usr/local/bin && \
  rm -rf /tmp/* /var/tmp/* /var/cache/apk/* /var/cache/distfiles/*

VOLUME ["/etc/openvpn"]

ADD bin /usr/local/bin

STOPSIGNAL SIGTERM

CMD ["/usr/local/bin/entrypoint.sh"]
