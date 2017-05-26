#
# Cookbook: hashicorp-vault
# License: Apache 2.0
#
# Copyright 2015-2016, Bloomberg Finance L.P.
#

poise_service_user 'vault' do
  group 'vault'
end

vault_install_git '0.7.2'

vault_config 'default' do
  address '127.0.0.1:8200'
  tls_cert_file '/etc/vault/ssl/certs/vault.crt'
  tls_key_file '/etc/vault/ssl/private/vault.key'
  notifies :reload, 'vault_service[vault]', :delayed
end

vault_service 'vault' do
  action [:enable, :start]
end
