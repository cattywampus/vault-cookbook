#
# Cookbook: hashicorp-vault
# License: Apache 2.0
#
# Copyright 2015-2016, Bloomberg Finance L.P.
#
poise_service_user 'vault' do
  group 'vault'
end

vault_install_binary '0.7.2'

vault_config 'default' do
  address '127.0.0.1:8200'
  notifies :reload, 'vault_service[vault]', :delayed
end

vault_service 'vault' do
  action [:enable, :start]
end
