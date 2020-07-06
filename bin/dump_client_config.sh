#!/bin/bash

#
# Dump OpenVPN Client configs
#

if [[ "${DEBUG}" == "true" ]]; then
    set -x
fi

display_info() {
    echo -e "\033[1;32mInfo: $1\033[0m"
}

display_error() {
    echo -e "\033[1;31mError: $1\033[0m"
}

export OVPN_ENV_FILE="${OVPN_DIR}/ovpn_env.sh"

if [[ ! -f "${OVPN_ENV_FILE}" ]]; then
    display_error "The [${OVPN_ENV_FILE}] file does not exist!"
    exit 1
else
    source ${OVPN_ENV_FILE}
fi

if [[ ! -f "${OVPN_PKI_DIR}/issued/${OVPN_SERVER_CN}.crt" ]]; then
    display_error "The EasyRSA PKI [${OVPN_PKI_DIR}/issued/${OVPN_SERVER_CN}.crt] does not exists."
    exit 1
fi

echo "client"
echo "nobind"
echo "dev ${OVPN_DEVICEN}"
echo "proto ${OVPN_PROTOCOL}"
echo "remote ${OVPN_SERVER_CN} ${OVPN_PORT}"
echo ""
echo "persist-key"
echo "persist-tun"
echo "key-direction 1"
echo ""
echo "auth SHA512"
echo "cipher ${OVPN_CIPHERS}"
echo "remote-cert-tls server"
if [ "${OVPN_ENABLE_LDAP}" == "true" ] ; then
    echo "auth-user-pass"
fi
echo ""
echo "verb 3"
echo ""
echo "<ca>"
cat ${OVPN_PKI_DIR}/ca.crt
echo "</ca>"
echo ""
echo "<tls-auth>"
cat ${OVPN_PKI_DIR}/ta.key
echo "</tls-auth>"
if [ "${OVPN_ENABLE_LDAP}" == "false" ] ; then
    echo ""
    echo "<cert>"
    cat ${OVPN_PKI_DIR}/issued/client.crt
    echo "</cert>"
    echo "<key>"
    cat ${OVPN_PKI_DIR}/private/client.key
    echo "</key>"
fi
