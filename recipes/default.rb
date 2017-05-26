#
# Cookbook: hashicorp-vault
# License: Apache 2.0
#
# Copyright 2015-2016, Bloomberg Finance L.P.
#
poise_service_user node['hashicorp-vault']['service_user'] do
  group node['hashicorp-vault']['service_group']
  not_if { node['hashicorp-vault']['service_user'] == 'root' }
end

vault_install_binary node['hashicorp-vault']['version']

config = vault_config node['hashicorp-vault']['config']['path'] do |r|
  owner node['hashicorp-vault']['service_user']
  group node['hashicorp-vault']['service_group']

  if node['hashicorp-vault']['config']
    node['hashicorp-vault']['config'].each_pair { |k, v| r.send(k, v) }
  end
  notifies :reload, "vault_service[#{node['hashicorp-vault']['service_name']}]", :delayed
end

vault_service node['hashicorp-vault']['service_name'] do |r|
  user node['hashicorp-vault']['service_user']
  group node['hashicorp-vault']['service_group']
  config_path node['hashicorp-vault']['config']['path']
  disable_mlock config.disable_mlock
  program "/opt/vault/#{node['hashicorp-vault']['version']}/vault"

  if node['hashicorp-vault']['service']
    node['hashicorp-vault']['service'].each_pair { |k, v| r.send(k, v) }
  end
  action [:enable, :start]
end
