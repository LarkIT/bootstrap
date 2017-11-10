#!/bin/bash

# Generic Bootstrap

# Set hostname (Mostly for AWS)
[ -d /etc/cloud/cloud.cfg.d ] && echo "preserve_hostname: true" > /etc/cloud/cloud.cfg.d/99_hostname.cfg
hostnamectl set-hostname ${hostname}

sleep 10

# Updates and install Puppet Agent
yum -y update
yum -y install https://yum.puppetlabs.com/puppetlabs-release-pc1-el-7.noarch.rpm
yum -y install puppet-agent

## Role
#mkdir -p /etc/puppetlabs/facter/facts.d
#echo "role=$role" > /etc/puppetlabs/facter/facts.d/role.txt
mkdir -p /etc/puppetlabs/puppet
cat > /etc/puppetlabs/puppet/csr_attributes.yaml << YAML
# custom_attributes:
#     1.2.840.113549.1.9.7: mySuperAwesomePassword
extension_requests:
#    pp_environment: ${pp_env}
    pp_role: ${role}
    pp_region: ${region}
    pp_application: ${host_prefix}
YAML

# Configure Puppet Agent
PATH=$PATH:/opt/puppetlabs/puppet/bin
augtool -s "set /files/etc/puppetlabs/puppet/puppet.conf/agent/server ${puppet_server}"
augtool -s "set /files/etc/puppetlabs/puppet/puppet.conf/agent/environment ${puppet_env}"
systemctl enable puppet

echo " *** Don't forget to \"reboot\" to apply updates ***"
