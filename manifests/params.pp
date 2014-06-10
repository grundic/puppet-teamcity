
class teamcity::params {
  $agent_user              = 'teamcity'
  $agent_user_home         = undef
  $manage_agent_user_home  = false
  $agent_group             = 'teamcity'
  $manage_user             = false
  $manage_group            = false
  $service_ensure          = 'running'
  $service_enable          = true
  $server_url              = 'http://builder'
  $archive_name            = 'buildAgent.zip'
  $download_url            = "${server_url}/update/${archive_name}"
  $agent_dir               = '/opt/build-agent'
  $teamcity_agent_mem_opts = '-Xms2048m -Xmx2048m -XX:+HeapDumpOnOutOfMemoryError'
}
