describe file('/opt/vault/0.7.2/vault') do
  it { should be_file }
  it { should be_executable }
end

describe group('vault') do
  it { should exist }
end

describe user('vault') do
  it { should exist }
end

%w(/opt/vault /opt/vault/0.7.2).each do |path|
  describe directory(path) do
    it { should exist }
    its('mode') { should cmp '0755' }
  end
end

describe directory('/etc/vault') do
  it { should exist }
  its('owner') { should eq 'vault' }
  its('group') { should eq 'vault' }
  its('mode') { should cmp '0755' }
end

describe file('/etc/vault/vault.json') do
  it { should be_file }
  it { should be_owned_by 'vault' }
  it { should be_grouped_into 'vault' }
  its('mode') { should cmp '0640' }
end

describe service('vault') do
  it { should be_installed }
  it { should be_enabled }
  it { should be_running }
end

describe file('/usr/local/bin/vault') do
  it { should exist }
  it { should be_symlink }
  it { should be_linked_to '/opt/vault/0.7.2/vault' }
end
