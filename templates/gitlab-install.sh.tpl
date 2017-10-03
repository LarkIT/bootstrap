#!/bin/bash

PATH=$PATH:/opt/puppetlabs/bin

# Firewall
if [ -x /bin/firewall-cmd ]; then
  firewall-cmd --zone=public --permanent --add-service=http
  firewall-cmd --zone=public --permanent --add-service=https
  firewall-cmd --reload
fi

# Bootstrap for gitlab server
puppet module install vshn-gitlab

# Temporary SSL Cert
openssl req -x509 -newkey rsa:4096 -nodes -keyout /etc/pki/tls/private/localhost.key -out /etc/pki/tls/certs/localhost.crt -days 3650 -subj "/C=US/ST=Colorado/L=Denver/O=SelfSignedCert/OU=IT Department/CN=$(hostname -f)"

cat  << 'END_OF_GITLAB_PP' > /root/gitlab.pp
class {'::gitlab':
  external_url => "https://$${::fqdn}",
    nginx        => {
      redirect_http_to_https => true,
      ssl_certificate     => '/etc/pki/tls/certs/localhost.crt',
      ssl_certificate_key => '/etc/pki/tls/private/localhost.key',
  },
}
END_OF_GITLAB_PP


puppet apply --verbose /root/gitlab.pp

