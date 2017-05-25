property :version, String, name_property: true
property :package_name, String, default: 'vault'
property :source, String

default_action :install

action :install do
  package 'install vault package' do
    package_name new_resource.package_name
    version new_resource.version
    source new_resource.source
    action :upgrade
  end
end

action :remove do
  package 'remove vault package' do
    package_name new_resource.package_name
    action :remove
  end
end

