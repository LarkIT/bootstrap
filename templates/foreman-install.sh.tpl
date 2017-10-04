#!/bin/bash

# Basic foreman setup, requires working git server with control-repo populated

# Settings you should edit
GIT_SERVER='git@${gitlab_server}'
CONTROL_REPO="$${GIT_SERVER}:puppet/control-repo"
HOSTNAME="$(hostname -f)"
DOMAINNAME="$(hostname -d)"
DNS_ALT_NAMES="puppet.$${DOMAINNAME},puppet,foreman.$${DOMAINNAME},foreman"

# -------------------------------------
# You shouldn't need to edit these
SSH_KEY_FILE='/opt/puppetlabs/server/data/puppetserver/.ssh/id_rsa'
PUPPET='/opt/puppetlabs/puppet/bin/puppet'
SUDO_PUPPET='sudo -H -u puppet'
REQ_PKGS='epel-release git puppetserver puppet-agent'
MAX_RETRIES=60
RETRY_SLEEP_TIME=60

# Install pkgs if not installed
function install_pkgs {
  pkgs=$$*
  local install_pkg=''
  for pkg in $$REQ_PKGS; do
    rpm -q $$pkg || install_pkg="$${install_pkg} $${pkg}"
  done
  [ -z "$$install_pkg" ] || yum install -y $${install_pkg}
}

# Retry/Sleep tracking
function retry_sleep {
  if [ $$tries -le $$MAX_RETRIES ]; then
    echo ""
    echo "Try: $$tries / $$MAX_RETRIES"
    echo "Sleeping $$RETRY_SLEEP_TIME for retry..."
    echo '------------'
    sleep $$RETRY_SLEEP_TIME
  else
    echo '----------------------'
    echo '- FAILED INSTALLTION -'
    echo '----------------------'
    echo ""
    echo -e "\n\n\t *** FAILED BOOTSTRAP! \n\t *** SEE: /var/log/cloud-init-output.log\n\n" >> /etc/motd
    exit 1
  fi
}

### MAIN
set +e # exit on error

# Install Stuff
rpm -q puppetlabs-release-pc1 || yum install -y https://yum.puppetlabs.com/puppetlabs-release-pc1-el-7.noarch.rpm
install_pkgs $$REQ_PKGS

# Get out of /root (prevents errors while using sudo)
cd /tmp

# Ensure we have an SSH Key
if [ ! -f $$SSH_KEY_FILE ]; then
  $$SUDO_PUPPET ssh-keygen -t rsa -b 4096 -f $$SSH_KEY_FILE -P ""
fi

# Test SSH Access (loop)
tries=0
while true; do
  ((tries++))
  echo "Testing SSH Access to $${GIT_SERVER}..."
  $$SUDO_PUPPET /bin/ssh -nTo 'StrictHostKeyChecking=no' $${GIT_SERVER}
  return=$$?
  if [ $$return == 0 ]; then
    echo "Success!"
    break
  else
    echo -e "\n***********\n"
    echo "There is a problem with the puppet ssh key access to $${GIT_SERVER}"
    echo "You need to add this SSH public key to a 'puppet-server' user in GitLab:"
    echo ""
    cat $${SSH_KEY_FILE}.pub
    retry_sleep
  fi
done

# Test Repo Access (loop)
tries=0
while true; do
  ((tries++))
  $$SUDO_PUPPET git ls-remote $${CONTROL_REPO}
  return=$$?
  if [ $$return == 0 ]; then
    echo "Success!"
    break
  else
    echo -e "\n***********\n"
    echo "There is a problem with puppet user access to the Git Repo: $${CONTROL_REPO}"
    echo "You need to grant the 'puppet-server' user in GitLab 'reporter' access to the group for the control-repo."
    retry_sleep
  fi
done

# Install puppet modules
#git clone https://github.com/puppetlabs/puppetlabs-stdlib.git /etc/puppetlabs/code/environments/production/modules/stdlib
#git clone https://github.com/voxpupuli/puppet-r10k.git /etc/puppetlabs/code/environments/production/modules/r10k
#git clone https://github.com/puppetlabs/puppetlabs-git.git /etc/puppetlabs/code/environments/production/modules/git
$$PUPPET module list | grep -q r10k || $$PUPPET module install puppet-r10k
#$$PUPPET module list | grep -q puppetserver || $$PUPPET module install puppet-puppetserver

# Install R10k using puppet
FACTER_gitremote="$${CONTROL_REPO}" $$PUPPET apply -e 'class { r10k: remote => "$${::gitremote}"  }'

# This seems dubious, like a packaging error?
chown -hR puppet:puppet /etc/puppetlabs/code

# Deploy (or update) Puppet Code
$$SUDO_PUPPET r10k deploy environment -pv

# Helper Alias
grep -q 'alias r10k' /root/.bash_profile || echo "alias r10k='cd / && sudo -H -u puppet r10k'" >> /root/.bash_profile

# Copy hieradata in (hacky)
cp -f /etc/puppetlabs/code/environments/production/site/profile/files/hiera.yaml /etc/puppetlabs/puppet/hiera.yaml

# Temporarily set this fact directly
mkdir -p /etc/puppetlabs/facter/facts.d
echo "role=foreman" > /etc/puppetlabs/facter/facts.d/role.txt

# Puppet Cert
hostcert=$$($$PUPPET config print hostcert)
[ -f "$$hostcert" ] || $$PUPPET cert generate $${HOSTNAME} --allow-dns-alt-names "$${DNS_ALT_NAMES}"

# Seriously hacky business here
# puppetserver.conf:    ruby-load-path: [/opt/puppetlabs/puppet/lib/ruby/vendor_ruby,/etc/puppetlabs/code/environments/production/modules/gms/lib]
PUPPETSERVER_CONF="/etc/puppetlabs/puppetserver/conf.d/puppetserver.conf"
grep -q 'gms/lib' $$PUPPETSERVER_CONF || sed -i -r 's#(ruby-load-path:.*)]#\1, /etc/puppetlabs/code/environments/production/modules/gms/lib]#' $$PUPPETSERVER_CONF

systemctl enable puppetserver
systemctl start puppetserver
$$PUPPET agent -t

echo 'DONE!?'
exit 0

#mkdir -p /opt/puppetlabs/server/data/puppetserver/r10k
#chown -R puppet:puppet /etc/puppetlabs/code /opt/puppetlabs/puppet/cache/r10k /opt/puppetlabs/server/data/puppetserver/r10k
#chown -R puppet:puppet /etc/puppetlabs /opt/puppetlabs
#/opt/puppetlabs/bin/puppet agent -t
#sudo -u puppet r10k deploy environment -pv
#rm -rf /opt/puppetlabs/puppet/cache/r10k/*
