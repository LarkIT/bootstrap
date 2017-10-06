#!/bin/bash

# Internal Bootstrap - POST PULP DEPLOYMENT

# Set hostname (Mostly for AWS)
[ -d /etc/cloud/cloud.cfg.d ] && echo "preserve_hostname: true" > /etc/cloud/cloud.cfg.d/99_hostname.cfg
hostnamectl set-hostname ${hostname}

# Pulp System Repos
rm -vf /etc/yum.repos.d/*.repo
cat << 'EOF' > /etc/yum.repos.d/pulp-bootstrap.repo
[base]
name=CentOS-$releasever - Base
baseurl=http://${pulp_server}/pulp/repos/centos/$releasever/os/$basearch/
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-7

#released updates
[updates]
name=CentOS-$releasever - Updates
baseurl=http://${pulp_server}/pulp/repos/centos/$releasever/updates/$basearch/
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-7

[pulp2-stable]
name=Pulp 2 Production Releases
baseurl=http://${pulp_server}/pulp/repos/pulp/stable/2/7/x86_64/
enabled=1
gpgcheck=1
gpgkey=https://${pulp_server}/pulp/static/rpm-gpg/RPM-GPG-KEY-pulp-2

[puppetlabs-pc1-7-x86_64]
name=Puppet Labs PC1 Repository el 7 - $basearch
baseurl=http://${pulp_server}/pulp/repos/puppetlabs/el/7/PC1/x86_64
enabled=1
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-puppetlabs-PC1
       file:///etc/pki/rpm-gpg/RPM-GPG-KEY-puppet-PC1

EOF

# Updates and install Puppet Agent
yum -y update
rm -vf /etc/yum.repos.d/CentOS*.repo

#yum -y install https://yum.puppetlabs.com/puppetlabs-release-pc1-el-7.noarch.rpm
cd /etc/pki/rpm-gpg && curl -O -k https://${pulp_server}/pulp/static/rpm-gpg/RPM-GPG-KEY-puppetlabs-PC1
cd /etc/pki/rpm-gpg && curl -O -k https://${pulp_server}/pulp/static/rpm-gpg/RPM-GPG-KEY-puppet-PC1

yum -y install puppet-agent

## Role
mkdir -p /etc/puppetlabs/puppet
#mkdir -p /etc/puppetlabs/facter/facts.d
#echo "role=$role" > /etc/puppetlabs/facter/facts.d/role.txt
cat > /etc/puppetlabs/puppet/csr_attributes.yaml << YAML
# custom_attributes:
#     1.2.840.113549.1.9.7: mySuperAwesomePassword
extension_requests:
    pp_role: ${role}
YAML

# Configure Puppet Agent
PATH=$PATH:/opt/puppetlabs/puppet/bin
augtool -s "set /files/etc/puppetlabs/puppet/puppet.conf/agent/server ${puppet_server}"
augtool -s "set /files/etc/puppetlabs/puppet/puppet.conf/agent/environment ${puppet_env}"
systemctl enable puppet
puppet agent --onetime --no-usecacheonfailure --no-daemonize

echo " *** Don't forget to \"reboot\" to apply updates ***"
