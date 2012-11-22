
class teamcity::params {
    $username = "teamcity"
    $server_url = "http://builder"
    $archive_name = "buildAgent.zip"
    $download_url = "$server_url/update/$archive_name"
    $agent_dir = "build-agent"
    $destination_dir = "/var/tainted"
    $priority = "20"
    $teamcity_agent_mem_opts = "-Xms2048m -Xmx2048m -XX:+HeapDumpOnOutOfMemoryError"
}
