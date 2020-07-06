#!/bin/bash

#
# Generate OpenVPN Server configs
#

if [[ "${DEBUG}" == "true" ]]; then
    set -x
fi

# http://linuxcommand.org/lc3_man_pages/seth.html
set -e

# Convert 1.2.3.4/24 -> 255.255.255.0
cidr2mask()
{
    local i
    local netmask=""
    local cidr=${1#*/}
    local full_octets=$(($cidr/8))
    local partial_octet=$(($cidr%8))

    for ((i=0; i<4; i+=1)); do
        if [[ ${i} -lt ${full_octets} ]]; then
            netmask+=255
        elif [[ ${i} -eq ${full_octets} ]]; then
            netmask+=$((256 - 2**(8-${partial_octet})))
        else
            netmask+=0
        fi
        [[ $i -lt 3 ]] && netmask+=.
    done
    echo ${netmask}
}

get_route() {
    echo ${1%/*} $(cidr2mask $1)
}

display_info() {
    echo -e "\033[1;32mInfo: $1\033[0m"
}

display_error() {
    echo -e "\033[1;31mError: $1\033[0m"
}

export OVPN_ENV_FILE="${OVPN_DIR}/ovpn_env.sh"
export OVPN_CONFIG_FILE="${OVPN_DIR}/server.conf"

if [[ -f "${OVPN_ENV_FILE}" ]] && [[ -f "${OVPN_CONFIG_FILE}" ]]; then
    display_info "The Config File [${OVPN_ENV_FILE}] and [${OVPN_CONFIG_FILE}] already exists."
    exit 0
fi

[[ -z "${OVPN_SERVER_CN}" ]] && display_error "The [OVPN_SERVER_CN] is empty!" && exit 1

[[ -z "${OVPN_ENABLE_LDAP}" ]] && export OVPN_ENABLE_LDAP="false"
# LDAP Variables
[[ "${OVPN_ENABLE_LDAP}" == "true" ]] && [[ -z "${OVPN_LDAP_URI}" ]] && display_error "The [OVPN_LDAP_URI] is empty!" && exit 1
[[ "${OVPN_ENABLE_LDAP}" == "true" ]] && [[ -z "${OVPN_LDAP_BASE_DN}" ]] && display_error "The [OVPN_LDAP_BASE_DN] is empty!" && exit 1
[[ -z "${OVPN_LDAP_TLS_VALIDATE_CERT}" ]] && export OVPN_LDAP_TLS_VALIDATE_CERT="false"

# OpenVPN Variables
[[ -z "${OVPN_DEVICEN}" ]] && export OVPN_DEVICEN="tun"
[[ -z "${OVPN_PORT}" ]] && export OVPN_PORT="1194"
[[ -z "${OVPN_PROTOCOL}" ]] && export OVPN_PROTOCOL="udp"

[[ -z "${OVPN_SERVER}" ]] && export OVPN_SERVER="10.8.0.0/16"
[[ -z "${OVPN_DNS_SERVERS}" ]] && export OVPN_DNS_SERVERS="8.8.8.8,114.114.114.114"
if [[ -n "${OVPN_DNS_SERVERS}" ]]; then
    export OVPN_DNS_SERVERS=($(echo ${OVPN_DNS_SERVERS} | tr ',' ' '))
fi
if [[ -n "${OVPN_ROUTES}" ]]; then
    export OVPN_ROUTES=($(echo ${OVPN_ROUTES} | tr ',' ' '))
fi

[[ -z "${OVPN_CLIENT_TO_CLIENT}" ]] && export OVPN_CLIENT_TO_CLIENT="true"

[[ -z "${OVPN_CIPHERS}" ]] && export OVPN_CIPHERS="AES-256-CBC"
[[ -z "${OVPN_TLS_CIPHERS}" ]] && export OVPN_TLS_CIPHERS="TLS-DHE-RSA-WITH-AES-256-GCM-SHA384:TLS-DHE-RSA-WITH-AES-256-CBC-SHA256:TLS-DHE-RSA-WITH-AES-128-GCM-SHA256:TLS-DHE-RSA-WITH-AES-128-CBC-SHA256"

# When using --net=host, use this to specify nat device.
[[ -z "${OVPN_NATDEVICE}" ]] && export OVPN_NATDEVICE="eth0"

echo "dev ${OVPN_DEVICEN}" > ${OVPN_CONFIG_FILE}
echo "port ${OVPN_PORT}" >> ${OVPN_CONFIG_FILE}
echo "proto ${OVPN_PROTOCOL}" >> ${OVPN_CONFIG_FILE}
echo "" >> ${OVPN_CONFIG_FILE}
echo "ca ${OVPN_PKI_DIR}/ca.crt" >> ${OVPN_CONFIG_FILE}
echo "dh ${OVPN_PKI_DIR}/dh.pem" >> ${OVPN_CONFIG_FILE}
echo "key ${OVPN_PKI_DIR}/private/${OVPN_SERVER_CN}.key" >> ${OVPN_CONFIG_FILE}
echo "cert ${OVPN_PKI_DIR}/issued/${OVPN_SERVER_CN}.crt" >> ${OVPN_CONFIG_FILE}
echo "tls-auth ${OVPN_PKI_DIR}/ta.key 0" >> ${OVPN_CONFIG_FILE}
echo "" >> ${OVPN_CONFIG_FILE}
echo "server $(get_route ${OVPN_SERVER})" >> ${OVPN_CONFIG_FILE}
if [[ -n "${OVPN_DNS_SERVERS}" ]]; then
    for OVPN_DNS_SERVER in "${OVPN_DNS_SERVERS[@]}"
    do
        echo "push \"dhcp-option DNS ${OVPN_DNS_SERVER}\"" >> ${OVPN_CONFIG_FILE}
    done
fi
if [[ -n "${OVPN_ROUTES}" ]]; then
    for OVPN_ROUTE in "${OVPN_ROUTES[@]}"
    do
        echo "push \"route $(get_route ${OVPN_ROUTE})\"" >> ${OVPN_CONFIG_FILE}
    done
fi
echo "" >> ${OVPN_CONFIG_FILE}
echo "user nobody" >> ${OVPN_CONFIG_FILE}
echo "group nogroup" >> ${OVPN_CONFIG_FILE}
echo "keepalive 10 120" >> ${OVPN_CONFIG_FILE}
echo "# As we're using LDAP, each client can use the same certificate" >> ${OVPN_CONFIG_FILE}
echo "duplicate-cn" >> ${OVPN_CONFIG_FILE}
if [[ "${OVPN_CLIENT_TO_CLIENT}" == "true" ]]; then
    echo "client-to-client" >> ${OVPN_CONFIG_FILE}
fi
echo "# Do not force renegotiation of client" >> ${OVPN_CONFIG_FILE}
echo "reneg-sec 0" >> ${OVPN_CONFIG_FILE}
echo "" >> ${OVPN_CONFIG_FILE}
echo "auth SHA512" >> ${OVPN_CONFIG_FILE}
echo "cipher ${OVPN_CIPHERS}" >> ${OVPN_CONFIG_FILE}
echo "tls-cipher ${OVPN_TLS_CIPHERS}" >> ${OVPN_CONFIG_FILE}
echo "persist-key" >> ${OVPN_CONFIG_FILE}
echo "persist-tun" >> ${OVPN_CONFIG_FILE}
echo "key-direction 0" >> ${OVPN_CONFIG_FILE}
echo "" >> ${OVPN_CONFIG_FILE}
echo "status /tmp/status.log" >> ${OVPN_CONFIG_FILE}
echo "verb 3" >> ${OVPN_CONFIG_FILE}
if [[ "${OVPN_ENABLE_LDAP}" == "true" ]]; then
    echo "" >> ${OVPN_CONFIG_FILE}
    echo "plugin /usr/lib/openvpn-auth-ldap.so \"/etc/openvpn/ldap.conf\"" >> ${OVPN_CONFIG_FILE}
    # echo "plugin /usr/lib/openvpn/plugins/openvpn-plugin-auth-pam.so openvpn" >> ${OVPN_CONFIG_FILE}
    echo "client-cert-not-required" >> ${OVPN_CONFIG_FILE}
    echo "username-as-common-name" >> ${OVPN_CONFIG_FILE}
fi
echo "" >> ${OVPN_CONFIG_FILE}

export OVPN_VARIABLES=($(env | grep '^OVPN_'))
for OVPN_VARIABLE in "${OVPN_VARIABLES[@]}"
do
    echo "declare -x ${OVPN_VARIABLE}" >> ${OVPN_ENV_FILE}
done

display_info "Successfully Generated OpenVPN Config."
