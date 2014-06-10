
class teamcity::params {
  $agent_user              = 'teamcity'
  $agent_group             = 'teamcity'
  $manage_user             = false
  $manage_group            = false
  $service_ensure          = 'running'
  $service_enable          = true
  $server_url              = 'http://builder'
  $archive_name            = 'buildAgent.zip'
  $download_url            = "${server_url}/update/${archive_name}"
  $agent_dir               = 'build-agent'
  $destination_dir         = '/var/tainted'
  $teamcity_agent_mem_opts = '-Xms2048m -Xmx2048m -XX:+HeapDumpOnOutOfMemoryError'
}
