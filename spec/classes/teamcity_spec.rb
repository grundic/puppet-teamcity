require 'spec_helper'
require 'puppet'

def include_systemd?(facts)
  if ['RedHat', 'CentOS', 'Fedora', 'Scientific', 'OracleLinux', 'SLC'].include? facts[:operatingsystem] and Puppet::Util::Package.versioncmp(facts[:operatingsystemmajrelease], '7') >= 0
    return true
  elsif ['Debian'].include? facts[:operatingsystem] and Puppet::Util::Package.versioncmp(facts[:operatingsystemmajrelease], '8') >= 0
    return true
  elsif ['Ubuntu'].include? facts[:operatingsystem] and Puppet::Util::Package.versioncmp(facts[:operatingsystemmajrelease], '15') >= 0
    return true
  else
    return false
  end
end

describe 'teamcity', :type => 'class' do

  default_params = {}

  Puppet::Util::Log.level = :debug
  Puppet::Util::Log.newdestination(:console)


  on_supported_os.each do |os, facts|
    context "on #{os}" do
      let(:facts) do
        facts
      end

      context 'main class tests' do
        it { should compile.with_all_deps }
        it { should contain_class('teamcity') }
        it { should contain_class('teamcity::params') }
      end

      context 'installation class tests' do
        it { should contain_wget__fetch('teamcity-buildagent').with(
          'source' => 'http://builder/update/buildAgent.zip',
        # 'destination' => '/tmp/buildAgent.zip'  # TODO: tmp doesn't work on Mac
        ) }

        it { should contain_exec('extract-agent-archive').with(
          # 'command' => 'unzip /tmp/buildAgent.zip -d /opt/build-agent' # TODO `tmp` doesn't work on Mac
          'creates' => '/opt/build-agent/conf'
        ).that_requires('Wget::Fetch[teamcity-buildagent]') }

        it { should contain_file('agent-config').
          with(
            'ensure' => 'file',
            'path' => '/opt/build-agent/conf/buildAgent.properties',
            'replace' => 'no',
            'group' => 'teamcity',
            'owner' => 'teamcity',
          ).
          that_requires('Exec[extract-agent-archive]')
        }

        it { should contain_exec('chown-agent-dir').with(
          'command' => 'chown -R teamcity:teamcity /opt/build-agent'
        ).that_requires('Exec[extract-agent-archive]').
          that_subscribes_to('Exec[extract-agent-archive]')
        }

        it { should contain_file('/opt/build-agent/bin/agent.sh').
          with('mode' => '0755').
          that_requires('Exec[extract-agent-archive]')
        }
      end

      context 'configuration class tests' do

        # TODO: how to check for a function call `create_ini_settings`?

        unless include_systemd?(facts)
          context 'with init.d system' do
            let (:params) { default_params.merge({:service_provider => 'init'}) }
            it { should contain_file('/etc/init.d/build-agent').with(
              'ensure' => 'file',
              'content' => /File is managed by Puppet/
            ) }
            it { should contain_file('/lib/systemd/system/build-agent.service').with(
              'ensure' => 'absent'
            ) }

            it 'should render init template' do
              harness = TemplateHarness.new('templates/build-agent.erb', params)
              harness.set('@agent_dir', '/opt/build-agent')
              result = harness.run
              expect(result).to match /\/opt\/build-agent\/bin\/agent\.sh/
            end
          end

          it { should contain_file('/etc/profile.d/teamcity.sh').with(
            'owner' => 'root',
            'group' => 'root',
            'mode' => '0755',
            'content' => /export TEAMCITY_AGENT_MEM_OPTS=/
          ) }

          context 'service class tests' do
            context 'with init.d system' do
              let (:params) { default_params.merge({:service_provider => 'init'}) }

              it { should contain_service('build-agent').with(
                'ensure' => 'running',
                'enable' => true,
                'provider' => nil
              ).
                that_requires('File[/etc/init.d/build-agent]')
              }

              it { should contain_file('/lib/systemd/system/build-agent.service').with(
                'ensure' => 'absent'
              ) }
            end
          end
        end

        if include_systemd?(facts)
          context 'with systemd system' do
            let (:params) { default_params.merge({:service_provider => 'systemd'}) }
            it { should contain_file('/lib/systemd/system/build-agent.service').with(
              'ensure' => 'file',
              'owner' => 'root',
              'group' => 'root',
              'mode' => '0755',
              'content' => /Description=TeamCity Build Agent/
            ).
              that_notifies('Exec[systemd_reload]')
            }
            it { should contain_file('/etc/init.d/build-agent').with(
              'ensure' => 'absent'
            ) }

            it 'should render systemd template' do
              harness = TemplateHarness.new('templates/build-agent-service.erb', params)
              harness.set('@agent_dir', '/opt/build-agent')
              result = harness.run
              expect(result).to match /ExecStart=\/opt\/build-agent\/bin\/agent\.sh start/
            end

            it { should contain_service('build-agent.service').with(
              'ensure' => 'running',
              'enable' => true,
              'provider' => 'systemd'
            ).
              that_requires('File[/lib/systemd/system/build-agent.service]')
            }

            it { should contain_exec('systemd_reload').with(
              'command' => '/bin/systemctl daemon-reload',
              'refreshonly' => true
            ).
              that_subscribes_to('File[/lib/systemd/system/build-agent.service]')
            }

            it { should contain_file('/etc/init.d/build-agent').with(
              'ensure' => 'absent'
            ) }
          end
        end

      end
    end
  end
end