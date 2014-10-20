
class teamcity::agent::install {
  wget::fetch { 'teamcity-buildagent':
    source      => $teamcity::download_url,
    destination => "/tmp/${teamcity::archive_name}",
    timeout     => 0,
  }

  exec { 'extract-agent-archive':
    command   => "unzip /tmp/${teamcity::archive_name} -d ${teamcity::agent_dir}",
    creates   => "${teamcity::agent_dir}/conf",
    logoutput => 'on_failure',
  }

  file {'agent-config':
    ensure  => 'present',
    path    => "${teamcity::agent_dir}/conf/buildAgent.properties",
    replace => 'no',
    source  => "${teamcity::agent_dir}/conf/buildAgent.dist.properties",
    group   => $teamcity::agent_group,
    owner   => $teamcity::agent_user
  }

  exec { 'chown-agent-dir':
    command     => "chown -R ${teamcity::agent_user}:${teamcity::agent_group} ${teamcity::agent_dir}",
    subscribe   => Exec['extract-agent-archive'],
    refreshonly => true,
    logoutput   => 'on_failure',
  }

  # make 'bin' folder executable
  file { "${teamcity::agent_dir}/bin/":
    ensure  => 'present',
    mode    => '0755',
    recurse => true,
  }
}
