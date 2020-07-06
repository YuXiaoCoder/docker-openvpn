#!/bin/bash

if [[ "${DEBUG}" == "true" ]]; then
    set -x
fi

# http://linuxcommand.org/lc3_man_pages/seth.html
set -e

export OVPN_ENV_FILE="${OVPN_DIR}/ovpn_env.sh"

if [[ ! -f "${OVPN_ENV_FILE}" ]]; then
    display_error "The [${OVPN_ENV_FILE}] file does not exist!"
    exit 1
else
    source ${OVPN_ENV_FILE}
fi

export OVPN_LDAP_CONFIG="${OVPN_DIR}/ldap.conf"

echo "<LDAP>" > ${OVPN_LDAP_CONFIG}
echo "    URL ${OVPN_LDAP_URI}" >> ${OVPN_LDAP_CONFIG}
if [[ -n "${OVPN_LDAP_BIND_USER_DN}" ]] && [[ -n "${OVPN_LDAP_BIND_USER_PASS}" ]]; then
    echo "    BindDN ${OVPN_LDAP_BIND_USER_DN}" >> ${OVPN_LDAP_CONFIG}
    echo "    Password ${OVPN_LDAP_BIND_USER_PASS}" >> ${OVPN_LDAP_CONFIG}
fi
echo "    Timeout 15" >> ${OVPN_LDAP_CONFIG}
echo "    TLSEnable no" >> ${OVPN_LDAP_CONFIG}
echo "    FollowReferrals no" >> ${OVPN_LDAP_CONFIG}
echo "</LDAP>" >> ${OVPN_LDAP_CONFIG}
echo "" >> ${OVPN_LDAP_CONFIG}
echo "<Authorization>" >> ${OVPN_LDAP_CONFIG}
echo "    BaseDN \"ou=Users,${OVPN_LDAP_BASE_DN}\"" >> ${OVPN_LDAP_CONFIG}
echo "    SearchFilter \"(&(cn=%u))\"" >> ${OVPN_LDAP_CONFIG}
echo "    RequireGroup false" >> ${OVPN_LDAP_CONFIG}
echo "</Authorization>" >> ${OVPN_LDAP_CONFIG}
