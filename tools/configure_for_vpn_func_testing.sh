#!/usr/bin/env bash

# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
# WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
# License for the specific language governing permissions and limitations
# under the License.


set -e


IS_GATE=${IS_GATE:-False}
PROJECT_NAME=${PROJECT_NAME:-neutron-vpnaas}
REPO_BASE=${GATE_DEST:-$(cd $(dirname "$BASH_SOURCE")/../.. && pwd)}

source $REPO_BASE/neutron/tools/configure_for_func_testing.sh


function _install_vpn_package {
    if [ "$VENV" == "dsvm-functional-sswan" ]
    then
        IPSEC_PACKAGE=strongswan
    else
        IPSEC_PACKAGE=openswan
    fi

    echo_summary "Installing $IPSEC_PACKAGE"
    neutron_vpn_install_agent_packages
}


function _configure_vpn_ini_file {
    echo_summary "Configuring VPN ini file"

    local temp_ini=$(mktemp)
    cp $REPO_BASE/$PROJECT_NAME/etc/vpn_agent.ini $temp_ini
    if [ "$IPSEC_PACKAGE" == "strongswan" ]; then
        iniset_multiline $temp_ini vpnagent vpn_device_driver neutron_vpnaas.services.vpn.device_drivers.strongswan_ipsec.StrongSwanDriver
        if is_fedora; then
            iniset $temp_ini strongswan default_config_area /usr/share/strongswan/templates/config/strongswan.d
        fi
    else
        iniset_multiline $temp_ini vpnagent vpn_device_driver neutron_vpnaas.services.vpn.device_drivers.ipsec.OpenSwanDriver
    fi
    sudo install -d -o $STACK_USER /etc/neutron/
    sudo mv $temp_ini $Q_VPN_CONF_FILE
}


function configure_host_for_vpn_func_testing {
    echo_summary "Configuring for VPN functional testing"
    if [ "$IS_GATE" == "True" ]; then
        configure_host_for_func_testing
    fi
    _install_vpn_package
    _configure_vpn_ini_file
}


if [ "$IS_GATE" != "True" ]; then
    configure_host_for_vpn_func_testing
fi

