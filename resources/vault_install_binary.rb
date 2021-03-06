#
# Cookbook: hashicorp-vault
# License: Apache 2.0
#
# Copyright 2015-2016, Bloomberg Finance L.P.
#

resource_name :vault_install_binary

property :version, String, name_property: true
property :user, String, default: 'vault'
property :group, String, default: 'vault'
property :archive_basename, String, default: lazy {
  case node['kernel']['machine']
  when 'x86_64', 'amd64' then ['vault', version, node['os'], 'amd64'].join('_')
  when 'i386' then ['vault', version, node['os'], '386'].join('_')
  else ['vault', version, node['os'], node['kernel']['machine']].join('_')
  end.concat('.zip')
}
property :archive_url, String, default: lazy { "https://releases.hashicorp.com/vault/#{version}/#{archive_basename}" }
property :extract_to, String, default: '/opt/vault'

default_action :install

action :install do
  poise_service_user new_resource.user do
    group new_resource.group
  end

  [new_resource.extract_to, ::File.join(new_resource.extract_to, new_resource.version)].each do |dir|
    directory dir do
      mode '0755'
      owner new_resource.user
      group new_resource.group
      recursive true
    end
  end

  poise_archive new_resource.archive_url do
    destination ::File.join(new_resource.extract_to, new_resource.version)
    strip_components 0
    user new_resource.user
    group new_resource.group
  end

  file ::File.join(new_resource.extract_to, new_resource.version, 'vault') do
    mode '0755'
  end

  link '/usr/local/bin/vault' do
    to ::File.join(new_resource.extract_to, new_resource.version, 'vault')
  end
end

action :remove do
  poise_service_user new_resource.user do
    group new_resource.group
    action :remove
  end

  directory ::File.join(new_resource.extract_to, new_resource.version) do
    recursive true
    action :delete
  end

  link '/usr/local/bin/vault' do
    action :delete
    only_if 'test -L /usr/local/bin/vault'
  end
end
