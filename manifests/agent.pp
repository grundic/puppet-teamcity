
class teamcity::agent (
  $agent_name              = $::teamcity::params::agent_name,

  $agent_user              = $::teamcity::params::agent_user,
  $agent_user_home         = $::teamcity::params::agent_user_home,
  $manage_agent_user_home  = $::teamcity::params::manage_agent_user_home,
  $agent_group             = $::teamcity::params::agent_group,
  $manage_user             = $::teamcity::params::manage_user,
  $manage_group            = $::teamcity::params::manage_group,

  $server_url              = $::teamcity::params::server_url,
  $archive_name            = $::teamcity::params::archive_name,
  $download_url            = $::teamcity::params::download_url,
  $agent_dir               = $::teamcity::params::agent_dir,

  $service_ensure          = $::teamcity::params::service_ensure,
  $service_enable          = $::teamcity::params::service_enable,
  $teamcity_agent_mem_opts = $::teamcity::params::teamcity_agent_mem_opts,
  $custom_properties       = $::teamcity::params::custom_properties
) inherits ::teamcity::params {

  validate_string($agent_name)

  Exec { path => [ '/bin/', '/sbin/' , '/usr/bin/', '/usr/sbin/', '/usr/local/bin' ] }

  class {'teamcity::install':} ->
  class {'teamcity::config':} ~>
  class {'teamcity::service':} ~>
  Class['teamcity::agent']

  Group[$agent_group] ->
  User[$agent_user] ->
  Wget::Fetch['teamcity-buildagent'] ->
  Exec['extract-agent-archive'] ->
  File['agent-config'] ->
  Exec['chown-agent-dir'] ->
  File["${agent_dir}/bin/"] ->
  Augeas['buildAgent.properties'] ->
  Augeas['buildAgent.properties-custom'] ->
  Augeas['wrapper.conf'] ->
  File['/etc/init.d/build-agent'] ->
  Service['build-agent']
}
