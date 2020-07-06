#!/bin/bash

#
# Initialize the EasyRSA PKI
#

if [[ "${DEBUG}" == "true" ]]; then
    set -x
fi

# http://linuxcommand.org/lc3_man_pages/seth.html
set -e

display_info() {
    echo -e "\033[1;32mInfo: $1\033[0m"
}

display_error() {
    echo -e "\033[1;31mError: $1\033[0m"
}

if [[ -f "${OVPN_PKI_DIR}/issued/${OVPN_SERVER_CN}.crt" ]]; then
    display_info "The EasyRSA PKI [${OVPN_PKI_DIR}/issued/${OVPN_SERVER_CN}.crt] already exists."
    exit 0
fi

export OVPN_ENV_FILE="${OVPN_DIR}/ovpn_env.sh"

if [[ ! -f "${OVPN_ENV_FILE}" ]]; then
    display_error "The [${OVPN_ENV_FILE}] file does not exist!"
    exit 1
else
    source ${OVPN_ENV_FILE}
fi

export EASYRSA="/usr/share/easy-rsa"
echo 'set_var EASYRSA "/usr/share/easy-rsa"' > ${EASYRSA}/vars
echo 'set_var EASYRSA_SSL_CONF "${EASYRSA}/openssl-easyrsa.cnf"' >> ${EASYRSA}/vars
echo 'set_var EASYRSA_OPENSSL "openssl"' >> ${EASYRSA}/vars
echo "set_var EASYRSA_PKI \"${OVPN_PKI_DIR}\"" >> ${EASYRSA}/vars
echo "" >> ${EASYRSA}/vars
echo "set_var EASYRSA_BATCH \"true\"" >> ${EASYRSA}/vars
echo "set_var EASYRSA_REQ_CN \"${OVPN_SERVER_CN}\"" >> ${EASYRSA}/vars
echo "" >> ${EASYRSA}/vars
echo "set_var EASYRSA_REQ_COUNTRY \"ZA\"" >> ${EASYRSA}/vars
echo "set_var EASYRSA_REQ_PROVINCE \"Nowhere\"" >> ${EASYRSA}/vars
echo "set_var EASYRSA_REQ_CITY \"Nowhere\"" >> ${EASYRSA}/vars
echo "set_var EASYRSA_REQ_ORG \"Docker OpenVPN\"" >> ${EASYRSA}/vars
echo "set_var EASYRSA_REQ_EMAIL \"null@null.org\"" >> ${EASYRSA}/vars
echo "set_var EASYRSA_REQ_OU \"OpenVPN\"" >> ${EASYRSA}/vars
echo "set_var EASYRSA_KEY_SIZE 2048" >> ${EASYRSA}/vars
echo "" >> ${EASYRSA}/vars
echo "set_var EASYRSA_CA_EXPIRE 3650" >> ${EASYRSA}/vars
echo "set_var EASYRSA_CERT_EXPIRE 3650" >> ${EASYRSA}/vars
echo "set_var EASYRSA_CRL_DAYS 180" >> ${EASYRSA}/vars

display_info "Creating Server Certs..."
export EASYCMD="/usr/share/easy-rsa/easyrsa --vars=${EASYRSA}/vars"

${EASYCMD} init-pki

dd if=/dev/urandom of=${OVPN_PKI_DIR}/.rnd bs=256 count=1
${EASYCMD} build-ca nopass

${EASYCMD} gen-dh
openvpn --genkey --secret ${OVPN_PKI_DIR}/ta.key

# For a server key with a password, manually init; this is autopilot
${EASYCMD} build-server-full "${OVPN_SERVER_CN}" nopass

if [[ "${OVPN_ENABLE_LDAP}" == "false" ]]; then
    display_info "Creating Client Certs..."
    ${EASYCMD} build-client-full client nopass
fi

display_info "Successfully Initialize the EasyRSA PKI."
