#
# Cookbook: hashicorp-vault
# License: Apache 2.0
#
# Copyright 2015-2016, Bloomberg Finance L.P.
#

resource_name :vault_install_git

property :version, String, name_property: true
property :user, String, default: 'vault'
property :group, String, default: 'vault'
property :git_url, String, default: 'https://github.com/hashicorp/vault'
property :git_path, String, default: "#{node['go']['gopath']}/src/github.com/hashicorp/vault"
property :git_ref, String, default: lazy { "v#{version}" }

default_action :install

action :install do
  # Require Go > 1.8 as Vault depends on it
  node.default['go']['version'] = '1.8.3'
  include_recipe 'golang::default', 'build-essential::default'
  # Install required go packages for building Vault
  golang_package 'github.com/mitchellh/gox'
  golang_package 'github.com/tools/godep'
  golang_package 'golang.org/x/tools/cmd/cover'
  golang_package 'github.com/golang/go/src/cmd/vet'

  poise_service_user new_resource.user do
    group new_resource.group
  end

  # Ensure paths exist for checkout, or git will fail
  directory new_resource.git_path do
    action :create
    recursive true
  end

  git new_resource.git_path do
    repository new_resource.git_url
    reference new_resource.git_ref
    action :checkout
  end

  # Use godep to restore dependencies before attempting to compile
  if new_resource.version < '0.6.0'
    execute 'Restore GO dependencies' do
      command 'godep restore'
      cwd new_resource.git_path
      environment(PATH: "#{node['go']['install_dir']}/go/bin:#{node['go']['gobin']}:/usr/bin:/bin",
                  GOPATH: node['go']['gopath'])
    end
  end

  execute 'Build Vault' do
    command 'make bootstrap && make dev'
    cwd new_resource.git_path
    environment(PATH: "#{node['go']['install_dir']}/go/bin:#{node['go']['gobin']}:/usr/bin:/bin",
                GOPATH: node['go']['gopath'])
  end
end

action :remove do
  poise_service_user new_resource.user do
    group new_resource.group
    action :remove
  end

  directory new_resource.git_path do
    recursive true
    action :delete
  end
end
