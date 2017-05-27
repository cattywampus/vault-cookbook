#
# Cookbook: hashicorp-vault
# License: Apache 2.0
#
# Copyright 2015-2016, Bloomberg Finance L.P.
#
vault_install_git '0.7.2'

config = vault_config '/etc/vault/vault.json' do |r|
  owner 'vault'
  group 'vault'

  if node['hashicorp-vault']['config']
    node['hashicorp-vault']['config'].each_pair { |k, v| r.send(k, v) }
  end
  notifies :reload, 'vault_service[vault]', :delayed
end

vault_service 'vault' do |r|
  user 'vault'
  group 'vault'
  disable_mlock config.disable_mlock
  program ::File.join(node['go']['gopath'], 'src', 'github.com', 'hashicorp', 'vault', 'bin', 'vault')

  if node['hashicorp-vault']['service']
    node['hashicorp-vault']['service'].each_pair { |k, v| r.send(k, v) }
  end
  action [:enable, :start]
end
