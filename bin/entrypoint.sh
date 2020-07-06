#!/bin/bash

if [[ "${DEBUG}" == "true" ]]; then
    set -x
fi

display_info() {
    echo -e "\033[1;32mInfo: $1\033[0m"
}

display_error() {
    echo -e "\033[1;31mError: $1\033[0m"
}

# Generate OpenVPN Server configs
/bin/bash "/usr/local/bin/generate_server_config.sh"

export OVPN_ENV_FILE="${OVPN_DIR}/ovpn_env.sh"

if [[ ! -f "${OVPN_ENV_FILE}" ]]; then
    display_error "The [${OVPN_ENV_FILE}] file does not exist!"
    exit 1
else
    source ${OVPN_ENV_FILE}
fi

# Initialize the EasyRSA PKI
/bin/bash "/usr/local/bin/init_pki.sh"

# Create the VPN tunnel interface
mkdir -p /dev/net
if [[ ! -c /dev/net/tun ]]; then
    mknod /dev/net/tun c 10 200
fi

iptables -t nat -C POSTROUTING -s "${OVPN_SERVER}" -o "${OVPN_NATDEVICE}" -j MASQUERADE >/dev/null 2>&1
if [[ $? -ne 0 ]]; then
    iptables -t nat -A POSTROUTING -s "${OVPN_SERVER}" -o "${OVPN_NATDEVICE}" -j MASQUERADE
fi

for OVPN_ROUTE in "${OVPN_ROUTES[@]}"
do
    iptables -t nat -C POSTROUTING -s "${OVPN_ROUTE}" -o "${OVPN_NATDEVICE}" -j MASQUERADE >/dev/null 2>&1
    if [[ $? -ne 0 ]]; then
        iptables -t nat -A POSTROUTING -s "${OVPN_ROUTE}" -o "${OVPN_NATDEVICE}" -j MASQUERADE
    fi
done

display_info "Successfully Set Network."

if [ "${OVPN_ENABLE_LDAP}" == "true" ] ; then
    /bin/bash "/usr/local/bin/setup_ldap.sh"
fi

display_info "Running OpenVPN Server..."
exec openvpn --config ${OVPN_DIR}/server.conf
