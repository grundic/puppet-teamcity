
if $::kernel == 'windows' {
  include windows::java

  class {'teamcity':
    agent_dir             => 'C:/buildAgent',
    service_run_type      => 'standalone',
    agent_user            => 'vagrant',
    launcher_wrapper_conf => {
      'wrapper.app.parameter.11' => '-Dfile.encoding=UTF-8'
    }
  }
}
else {
  package {'unzip':
    ensure => installed
  }

  class { 'java':
    distribution => 'jre',
  }

  class {'::teamcity':
    agent_name            => "${hostname}-agent",
    server_url            => 'https://teamcity.jetbrains.com',
    manage_user           => true,
    manage_group          => true,
    custom_properties     => {
        'ownPort'                   => '59090',
        'system.teamcity.idea.home' => '%system.agent.home.dir%/tools/idea'
    },
    launcher_wrapper_conf => {
      'wrapper.app.parameter.11' => '-Dfile.encoding=UTF-8'
    }
  }
}
