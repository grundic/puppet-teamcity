# PRIVATE CLASS: do not call directly
class teamcity::agent::install {
  require teamcity::account

  if $::teamcity::download_url {
    $download_url = $::teamcity::download_url
  }
  else {
    $download_url = "${::teamcity::server_url}/update/${::teamcity::archive_name}"
  }

  if $::kernel == 'windows' {
    $agent_dir_win = regsubst($::teamcity::agent_dir, '/', '\\', 'G')
    $temp_dir_win = regsubst($::temp_dir, '/', '\\', 'G')

    download_file { 'Download Teamcity agent' :
      url                   => $download_url,
      destination_directory => $::temp_dir
    }

    file { $::teamcity::agent_dir:
      ensure => directory
    }

    exec { 'extract-agent-archive':
      command   => template("${module_name}/extract-agent-archive.ps1"),
      creates   => "${::teamcity::agent_dir}/conf",
      provider  => 'powershell',
      logoutput => true,
      require   => [Download_file['Download Teamcity agent'], File[$::teamcity::agent_dir]]
    }

    file {'agent-config':
      ensure             => 'present',
      path               => "${::teamcity::agent_dir}/conf/buildAgent.properties",
      replace            => 'no',
      source             => "${::teamcity::agent_dir}/conf/buildAgent.dist.properties",
      source_permissions => ignore,
      require            => Exec['extract-agent-archive']
    }
  }
  else {
    wget::fetch { 'teamcity-buildagent':
      source      => $download_url,
      destination => "${::temp_dir}/${::teamcity::archive_name}",
      flags       => ['--no-proxy'],
      timeout     => 0,
    }

    exec { 'extract-agent-archive':
      command   => "unzip ${::temp_dir}/${::teamcity::archive_name} -d ${::teamcity::agent_dir}",
      creates   => "${::teamcity::agent_dir}/conf",
      logoutput => 'on_failure',
      require   => Wget::Fetch['teamcity-buildagent']
    }

    file {'agent-config':
      ensure  => 'present',
      path    => "${::teamcity::agent_dir}/conf/buildAgent.properties",
      replace => 'no',
      source  => "${::teamcity::agent_dir}/conf/buildAgent.dist.properties",
      group   => $::teamcity::agent_group,
      owner   => $::teamcity::agent_user,
      require => Exec['extract-agent-archive']
    }

    exec { 'chown-agent-dir':
      command     => "chown -R ${::teamcity::agent_user}:${::teamcity::agent_group} ${::teamcity::agent_dir}",
      subscribe   => Exec['extract-agent-archive'],
      refreshonly => true,
      logoutput   => 'on_failure',
      require     => Exec['extract-agent-archive']
    }

    file { "${::teamcity::agent_dir}/bin/agent.sh":
      mode    => '0755',
      require => Exec['extract-agent-archive']
    }
  }
}
