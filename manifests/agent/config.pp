# PRIVATE CLASS: do not call directly
class teamcity::agent::config {
  $agent_name              = $teamcity::agent::agent_name
  $agent_user              = $teamcity::agent::agent_user
  $agent_user_home         = $teamcity::agent::agent_user_home
  $manage_agent_user_home  = $teamcity::agent::manage_agent_user_home
  $agent_group             = $teamcity::agent::agent_group
  $manage_group            = $teamcity::agent::manage_group
  $server_url              = $teamcity::agent::server_url
  $archive_name            = $teamcity::agent::archive_name
  $download_url            = $teamcity::agent::download_url
  $agent_dir               = $teamcity::agent::agent_dir
  $service_ensure          = $teamcity::agent::service_ensure
  $service_enable          = $teamcity::agent::agent_dir
  $service_run_type        = $teamcity::agent::service_run_type
  $custom_properties       = $teamcity::agent::custom_properties
  $launcher_wrapper_conf   = $teamcity::agent::launcher_wrapper_conf
  $teamcity_agent_mem_opts = $teamcity::agent::teamcity_agent_mem_opts

  $required_properties = {
    'serverUrl' => $server_url,
    'name'      => $agent_name
  }

  # configure buildAgent.properties
  $merged_params = merge($required_properties, $custom_properties)
  create_ini_settings(
    {'' => $merged_params},
    {'path' => "${agent_dir}/conf/buildAgent.properties" }
  )

  # configure launcher/conf/wrapper.conf
  create_ini_settings(
    {'' => $launcher_wrapper_conf},
    {'path' => "${agent_dir}/launcher/conf/wrapper.conf"}
  )

  if $::kernel == 'windows' {
    windows_env {'TEAMCITY_AGENT_MEM_OPTS':
      ensure    => present,
      value     => $teamcity_agent_mem_opts,
      mergemode => clobber,
    }
  }
  else {
    case $service_run_type {
      'init': {
        file { '/etc/init.d/build-agent':
          ensure  => 'present',
          owner   => 'root',
          group   => 'root',
          mode    => '0755',
          content => template("${module_name}/build-agent.erb"),
        }
      }
      'systemd': {
        file { '/lib/systemd/system/build-agent.service':
          ensure  => 'present',
          owner   => 'root',
          group   => 'root',
          mode    => '0755',
          content => template("${module_name}/build-agent-service.erb"),
        }
      }
      default: {
        fail("Unexpected service run type ${::service_run_type}!")
      }
    }

    file { '/etc/profile.d/teamcity.sh':
      owner   => 'root',
      group   => 'root',
      mode    => '0755',
      content => template("${module_name}/teamcity-profile.erb"),
    }
  }
}
