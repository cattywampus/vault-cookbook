#
# Cookbook: hashicorp-vault
# License: Apache 2.0
#
# Copyright 2015-2017, Bloomberg Finance L.P.
#

resource_name :vault_installation_binary

property :version, String, name_property: true
property :archive_checksum, String
property :extract_to, String, default: '/opt/vault'

default_action :create

installpath = ::File.join(new_resource.extract_to, new_resource.version)

action :create do
  [new_resource.extract_to, installpath].each do |path|
    directory path do
      mode '0755'
      recursive true
    end
  end

  # Still coming from poise
  ark basename do
    path installpath
    source archive_url
    checksum new_resource.archive_checksum
    action :put
  end

  link '/usr/local/bin/vault' do
    to ::File.join(installpath, 'vault')
  end
end

action :remove do
  directory installpath do
    recursive true
    action :delete
  end

  link '/usr/local/bin/vault' do
    action :delete
    only_if 'test -L /usr/local/bin/vault'
  end
end

def self.archive_url
  "https://releases.hashicorp.com/vault/#{new_resource.version}/" + basename
end

def self.basename
  case node['kernel']['machine']
  when 'x86_64', 'amd64' then ['vault', new_resource.version, node['os'], 'amd64'].join('_')
  when 'i386' then ['vault', new_resource.version, node['os'], '386'].join('_')
  else ['vault', new_resource.version, node['os'], node['kernel']['machine']].join('_')
  end.concat('.zip')
end
