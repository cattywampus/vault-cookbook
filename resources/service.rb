#
# Cookbook: hashicorp-vault
# License: Apache 2.0
#
# Copyright 2015-2016, Bloomberg Finance L.P.
#

resource_name :vault_service

property :service_name, String, name_property: true
property :config_path, String, default: '/etc/vault/vault.json'
property :directory_path, String, default: '/var/run/vault'
property :user, String, default: 'vault'
property :group, String, default: 'vault'
property :environment, Hash, default: { PATH: '/usr/local/bin:/usr/bin:/bin' }
property :disable_mlock, [true, false], default: false
property :program, String, default: '/usr/local/bin/vault'
property :log_level, String, default: 'info', equal_to: %w(trace debug info warn err)

default_action :enable

action :enable do
  directory new_resource.directory_path do
    owner new_resource.user
    group new_resource.group
    recursive true
  end

  package 'libcap2-bin' do
    only_if { node.platform_family?('debian') }
  end

  program_target = ::File.readlink(new_resource.program)

  execute "setcap cap_ipc_lock=+ep #{program_target}" do
    not_if { node.platform_family?('windows', 'mac_os_x', 'freebsd') }
    not_if { node.platform_family?('rhel') && node['platform_version'].to_i < 6 }
    not_if { new_resource.disable_mlock }
    not_if "getcap #{program_target}|grep cap_ipc_lock+ep"
  end
  poise_service new_resource.service_name do
    command "#{new_resource.program} server -config=#{new_resource.config_path} -log-level=#{new_resource.log_level}"
    directory new_resource.directory_path
    user new_resource.user
    environment new_resource.environment
    restart_on_update false
    options :sysvinit, template: 'hashicorp-vault:sysvinit.service.erb'
    options :systemd, template: 'hashicorp-vault:systemd.service.erb'

    if node.platform_family?('rhel') && node['platform_version'].to_i == 6
      provider :sysvinit
    end
    action :enable
  end
end

action :start do
  poise_service new_resource.service_name do
    action :start
  end
end

action :stop do
  poise_service new_resource.service_name do
    action :stop
  end
end

action :restart do
  poise_service new_resource.service_name do
    action :restart
  end
end

action :reload do
  poise_service new_resource.service_name do
    action :reload
  end
end
