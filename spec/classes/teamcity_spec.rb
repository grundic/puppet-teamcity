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
        it { should contain_wget__fetch('teamcity-buildagent') }


        # Base files
        it { should contain_file('agent-config') }
        it { should contain_file('/opt/build-agent/bin/agent.sh') }
      end

    end
  end
end