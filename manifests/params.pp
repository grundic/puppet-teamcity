# PRIVATE CLASS: do not use directly
class teamcity::params {
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

  if $::kernel == 'windows' {
    $agent_dir               = 'C:/buildAgent'
  }
  else {
    $agent_dir               = '/opt/build-agent'
  }

  $service_ensure          = 'running'
  $service_enable          = true
  if $::kernel == 'windows' {
    $service_run_type        = 'service'
  }
  else {
    if ($::operatingsystem == 'Debian' and versioncmp($::operatingsystemmajrelease, '7') >= 0) or ($::operatingsystem == 'Ubuntu' and versioncmp($::operatingsystemmajrelease, '15.04') >= 0) {
      $service_run_type = 'systemd'
    } else {
      $service_run_type = 'init'
    }
  }
  $teamcity_agent_mem_opts = '-Xms512m -Xmx1024m -XX:+HeapDumpOnOutOfMemoryError -Dfile.encoding=UTF-8'
  $custom_properties       = { }
  $launcher_wrapper_conf   = { }
}
