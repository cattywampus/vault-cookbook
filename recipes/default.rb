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

vault_config '/etc/vault/vault.json' do |r|
  owner 'vault'
  group 'vault'

  if node['hashicorp-vault']['config']
    node['hashicorp-vault']['config'].each_pair { |k, v| r.send(k, v) }
  end
  notifies :reload, 'vault_service[vault]', :delayed
end

vault_service 'vault' do
  action [:enable, :start]
end
