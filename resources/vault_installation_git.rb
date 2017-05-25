#
# Cookbook: hashicorp-vault
# License: Apache 2.0
#
# Copyright 2015-2016, Bloomberg Finance L.P.
#

resource_name :vault_install_git

property :version, String, name_property: true
property :git_url, String, default: 'https://github.com/hashicorp/vault'
property :git_path, String, default: "#{node['go']['gopath']}/src/github.com/hashicorp/vault"

default_action :install

action :install do
  # Require Go 1.6.1 as Vault depends on new functionality in net/http
  node.default['go']['version'] = '1.6.1'
  include_recipe 'golang::default', 'build-essential::default'
  # Install required go packages for building Vault
  golang_package 'github.com/mitchellh/gox'
  golang_package 'github.com/tools/godep'
  golang_package 'golang.org/x/tools/cmd/cover'
  golang_package 'github.com/golang/go/src/cmd/vet'

  # Ensure paths exist for checkout, or git will fail
  directory new_resource.git_path do
    action :create
    recursive true
  end

  git new_resource.git_path do
    repository new_resource.git_url
    reference options.fetch(:git_ref, "v#{new_resource.version}")
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
    command 'make dev'
    cwd new_resource.git_path
    environment(PATH: "#{node['go']['install_dir']}/go/bin:#{node['go']['gobin']}:/usr/bin:/bin",
                GOPATH: node['go']['gopath'])
  end
end

action :remove do
  directory new_resource.git_path do
    recursive true
    action :delete
  end
end
