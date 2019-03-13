require 'spec_helper'

describe 'sensuclassic::subscription', :type => :define do
  let(:pre_condition) do
    <<-'ENDofPUPPETcode'
    include ::sensuclassic
    ENDofPUPPETcode
  end
  context 'without whitespace in name' do
    let(:title) { 'mysubscription' }

    context 'defaults' do
      it { should contain_sensuclassic_client_subscription('mysubscription').with_base_path('/etc/sensu/conf.d') }
    end

    context 'setting params' do
      let(:params) { {
        :custom => { 'a' => 'b', 'array' => [ 'c', 'd' ] },
      } }

      it { should contain_sensuclassic_client_subscription('mysubscription').with(
        :custom => { 'a' => 'b', 'array' => [ 'c', 'd' ] }
      ) }
    end

    context 'ensure absent' do
      let(:params) { {
        :ensure => 'absent',
      } }

      it { should contain_sensuclassic_client_subscription('mysubscription').with_ensure('absent') }
    end
  end

  context 'notifications' do
    let(:title) { 'mysubscription' }

    it { should contain_sensuclassic_client_subscription('mysubscription').with(:notify => 'Service[sensu-client]' ) }
  end

  describe 'when sensuclassic::sensu_etc_dir => /opt/etc/sensu' do
    let(:pre_condition) do
      <<-'ENDofPUPPETcode'
      class {'sensuclassic':
        sensu_etc_dir => '/opt/etc/sensu';
      }
      ENDofPUPPETcode
    end
    let(:title) { 'mysubscription' }
    it { should contain_sensuclassic_client_subscription('mysubscription').with_base_path('/opt/etc/sensu/conf.d') }
  end

  context 'with char : in title' do
    let(:title) { 'roundrobin:foo' }

    it { should contain_sensuclassic_client_subscription('roundrobin:foo').with(:ensure => 'present', :file_name => 'subscription_roundrobin_foo.json') }
    it { should contain_file('/etc/sensu/conf.d/subscription_roundrobin_foo.json').with(:ensure => 'present' ) }
  end

  context 'with char : in title in windows' do
    let(:title) { 'roundrobin:foo' }
    let(:facts) {
      {
        :osfamily => 'windows',
        :os => { :release => { :major => '2012 R2' }}, # needed for sensuclassic::package
      }
    }

    it { should contain_sensuclassic_client_subscription('roundrobin:foo').with(:ensure => 'present' , :file_name => 'subscription_roundrobin_foo.json') }
    it { should contain_file('C:/opt/sensu/conf.d/subscription_roundrobin_foo.json').with(:ensure => 'present' ) }
  end
end
