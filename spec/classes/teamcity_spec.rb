require 'spec_helper'

describe 'teamcity', :type => 'class' do

  default_params = {}

  on_supported_os.each do |os, facts|
    context "on #{os}" do
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
            'ensure' => 'present',
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

        context 'with init.d system' do
          let (:params) { default_params.merge({:service_run_type => 'init'})}
          it { should contain_file('/etc/init.d/build-agent').with(
            'ensure' => 'present',
            'content' => /File is managed by Puppet/
          )}
          it { should contain_file('/lib/systemd/system/build-agent.service').with(
            'ensure' => 'absent'
          )}

          it 'should render init template' do
            harness = TemplateHarness.new('templates/build-agent.erb', params)
            harness.set('@agent_dir', '/opt/build-agent')
            result = harness.run
            expect(result).to match /\/opt\/build-agent\/bin\/agent\.sh/
          end
        end

        context 'with systemd system' do
          let (:params) { default_params.merge({:service_run_type => 'systemd'})}
          it { should contain_file('/lib/systemd/system/build-agent.service').with(
            'ensure' => 'present'
          )}
          it { should contain_file('/etc/init.d/build-agent').with(
            'ensure' => 'absent'
          )}

          it 'should render systemd template' do
            harness = TemplateHarness.new('templates/build-agent-service.erb', params)
            harness.set('@agent_dir', '/opt/build-agent')
            result = harness.run
            expect(result).to match /ExecStart=\/opt\/build-agent\/bin\/agent\.sh start/
          end
        end

        it { should contain_file('/etc/profile.d/teamcity.sh')}
      end

    end
  end
end