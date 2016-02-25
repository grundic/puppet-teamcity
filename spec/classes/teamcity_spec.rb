require 'spec_helper'

describe 'teamcity', :type => 'class' do

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

    end
  end
end