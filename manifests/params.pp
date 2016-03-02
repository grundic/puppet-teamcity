# PRIVATE CLASS: do not use directly
class teamcity::params {
  # general parameters
  $agent_name              = $::hostname
  $agent_user              = 'teamcity'
  $agent_user_home         = undef
  $manage_agent_user_home  = false
  $agent_group             = 'teamcity'
  $manage_user             = false
  $manage_group            = false

  $server_url              = 'http://builder'
  $archive_name            = 'buildAgent.zip'
  $download_url            = undef

  # installation path
  if $::kernel == 'windows' {
    $agent_dir             = 'C:/buildAgent'
  }
  else {
    $agent_dir             = '/opt/build-agent'
  }

  # service parameters
  $service_ensure          = 'running'
  $service_enable          = true
  $service_provider        = 'init'

  case $::operatingsystem {
    'RedHat', 'CentOS', 'Fedora', 'Scientific', 'OracleLinux', 'SLC': {
      if versioncmp($::operatingsystemmajrelease, '7') >= 0 {
        $service_providers = 'systemd'
      } else {
        $service_providers = ['init']
      }
    }
    'Amazon': {
      $service_providers = 'init'
    }
    'Debian': {
      if versioncmp($::operatingsystemmajrelease, '8') >= 0 {
        $service_providers = ['systemd', 'init']
      } else {
        $service_providers = [ 'init' ]
      }
    }
    'Ubuntu': {
      if versioncmp($::operatingsystemmajrelease, '15') >= 0 {
        $service_providers = 'systemd'
      } else {
        $service_providers = [ 'init' ]
      }
    }
    'windows': {
      $service_run_type    = ['service', 'standalone']
    }
    default: {
      fail("'${module_name}' provides no service parameters for '${::operatingsystem}' operating system!")
    }
  }

  # agent parameters
  $teamcity_agent_mem_opts = '-Xms512m -Xmx1024m -XX:+HeapDumpOnOutOfMemoryError -Dfile.encoding=UTF-8'
  $custom_properties       = { }
  $launcher_wrapper_conf   = { }
}
