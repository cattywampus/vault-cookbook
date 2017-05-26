#
# Cookbook: hashicorp-vault
# License: Apache 2.0
#
# Copyright 2015-2016, Bloomberg Finance L.P.
#

resource_name :vault_config

property :name, String, name_property: true
property :user, String, default: 'vault'
property :group, String, default: 'vault'
property :config_path, String, default: '/etc/vault/vault.json'
property :address, String
property :cluster_address, String
property :tls_disable, [true, false], equal_to: [true, false, 1, 0, 'yes', 'no'], default: true
property :tls_cert_file, String
property :tls_key_file, String
property :cache_size, Integer, default: 32000
property :disable_cache, [true, false], equal_to: [true, false], default: false
property :disable_mlock, [true, false], equal_to: [true, false], default: false
property :default_lease_ttl, String, default: '32d'
property :max_lease_ttl, String, default: '32d'
property :statsite_addr, String
property :statsd_addr, String
property :backend_type, String, default: 'inmem', equal_to: %w(consul etcd zookeeper dynamodb s3 mysql postgresql inmem file)
property :backend_options, Hash
property :habackend_type, String
property :habackend_options, Hash
property :telemetry_options, Hash, default: {}

default_action :create

action :create do
  directory ::File.dirname(new_resource.config_path) do
    owner new_resource.user
    group new_resource.group
    recursive true
  end

  file new_resource.config_path do
    content new_resource.to_json
    owner new_resource.user
    group new_resource.group
    mode '0640'
  end
end

action :remove do
  file new_resource.config_path do
    action :delete
  end
end

def tls?
  if tls_disable == true || tls_disable == 'yes' || tls_disable == 1
    false
  else
    true
  end
end

# Transforms the resource into a JSON format which matches the
# Vault service's configuration format.
# @see https://vaultproject.io/docs/config/index.html
def to_json
  # top-level
  config_keeps = %i(cache_size disable_cache disable_mlock default_lease_ttl max_lease_ttl)
  config = to_hash.keep_if do |k, _|
    config_keeps.include?(k.to_sym)
  end
  # listener
  listener_keeps = tls? ? %i(address cluster_address tls_cert_file tls_key_file) : %i(address cluster_address)
  listener_options = to_hash.keep_if do |k, _|
    listener_keeps.include?(k.to_sym)
  end.merge(tls_disable: tls_disable.to_s)
  config['listener'] = { 'tcp' => listener_options }
  # backend
  config['backend'] = { backend_type => (backend_options || {}) }
  # ha_backend, only some backends support HA
  if %w(consul etcd zookeeper dynamodb).include? habackend_type
    config['ha_backend'] = { habackend_type => (habackend_options || {}) }
  end
  config['telemetry'] = telemetry_options unless telemetry_options.empty?

  JSON.pretty_generate(config, quirks_mode: true)
end
