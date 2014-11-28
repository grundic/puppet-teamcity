# PRIVATE CLASS: do not call directly
class teamcity::agent::install {
  $agent_user   = $teamcity::agent::agent_user
  $agent_group  = $teamcity::agent::agent_group
  $archive_name = $teamcity::agent::archive_name
  $download_url = $teamcity::agent::download_url
  $agent_dir    = $teamcity::agent::agent_dir

  require teamcity::account

  wget::fetch { 'teamcity-buildagent':
    source      => $download_url,
    destination => "/tmp/${archive_name}",
    flags       => ['--no-proxy'],
    timeout     => 0,
  }

  exec { 'extract-agent-archive':
    command   => "unzip /tmp/${archive_name} -d ${agent_dir}",
    creates   => "${agent_dir}/conf",
    logoutput => 'on_failure',
    require   => Wget::Fetch['teamcity-buildagent']
  }

  file {'agent-config':
    ensure  => 'present',
    path    => "${agent_dir}/conf/buildAgent.properties",
    replace => 'no',
    source  => "${agent_dir}/conf/buildAgent.dist.properties",
    group   => $agent_group,
    owner   => $agent_user,
    require => Exec['extract-agent-archive']
  }

  exec { 'chown-agent-dir':
    command     => "chown -R ${agent_user}:${agent_group} ${agent_dir}",
    subscribe   => Exec['extract-agent-archive'],
    refreshonly => true,
    logoutput   => 'on_failure',
    require     => Exec['extract-agent-archive']
  }

  file { "${agent_dir}/bin/agent.sh":
    mode    => '0755',
    require => Exec['extract-agent-archive']
  }
}
