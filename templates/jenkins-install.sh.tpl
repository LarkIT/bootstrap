#!/bin/bash

PATH=$PATH:/opt/puppetlabs/bin

# Firewall
if [ -x /bin/firewall-cmd ]; then
  firewall-cmd --zone=public --permanent --add-service=http
  firewall-cmd --zone=public --permanent --add-service=https
  firewall-cmd --reload
fi

# Bootstrap for gitlab server
puppet module install rtyler/jenkins

# Temporary SSL Cert
openssl req -x509 -newkey rsa:4096 -nodes -keyout /etc/pki/tls/private/localhost.key -out /etc/pki/tls/certs/localhost.crt -days 3650 -subj "/C=US/ST=Colorado/L=Denver/O=SelfSignedCert/OU=IT Department/CN=$(hostname -f)"

cat  << 'END_OF_JENKINS_PP' > /root/jenkins.pp
include jenkins
END_OF_JENKINS_PP


puppet apply --verbose /root/jenkins.pp

cd /usr/bin
ln -s /opt/gitlab/embedded/bin/git* .
