
class teamcity::agent (
  $agent_name,
  $agent_user              = $teamcity::params::agent_user,
  $agent_user_home         = $teamcity::params::agent_user_home,
  $agent_group             = $teamcity::params::agent_group,
  $manage_user             = $teamcity::params::manage_user,
  $manage_group            = $teamcity::params::manage_group,
  $service_ensure          = $teamcity::params::service_ensure,
  $service_enable          = $teamcity::params::service_enable,
  $server_url              = $teamcity::params::server_url,
  $archive_name            = $teamcity::params::archive_name,
  $download_url            = $teamcity::params::download_url,
  $agent_dir               = $teamcity::params::agent_dir,
  $destination_dir         = $teamcity::params::destination_dir,
  $teamcity_agent_mem_opts = $teamcity::params::teamcity_agent_mem_opts) inherits ::teamcity::params {
  if $manage_group {
    if !defined(Group[$agent_group]) {
      group { $agent_group: ensure => 'present', }

      Group[$agent_group] -> Exec['extract-build-agent']
    }
  }

  if $manage_user {
    $group_require = $manage_group ? {
      true    => Group[$agent_group],
      default => undef,
    }

    if !defined(User[$agent_user]) {
      user { $agent_user:
        ensure     => 'present',
        home       => $agent_user_home,
        managehome => false,
        gid        => $agent_group,
        shell      => '/bin/sh',
        require    => $group_require,
      }
    }

    User[$agent_user] -> Exec['extract-build-agent']
  }

  wget::fetch { 'teamcity-buildagent':
    source      => $download_url,
    destination => "/tmp/${archive_name}",
    timeout     => 0,
  }

  file { $destination_dir: ensure => 'directory', }

  exec { 'extract-build-agent':
    command   => "unzip -d ${destination_dir}/${agent_dir} /tmp/${archive_name} && cp ${destination_dir}/${agent_dir}/conf/buildAgent.dist.properties ${destination_dir}/${agent_dir}/conf/buildAgent.properties && chown -R ${agent_user}:${agent_group} ${destination_dir}/${agent_dir}",
    path      => '/usr/bin:/usr/sbin:/bin:/usr/local/bin:/opt/local/bin',
    creates   => "${destination_dir}/${agent_dir}",
    logoutput => 'on_failure',
  }

  # make 'bin' folder executable
  file { "${destination_dir}/${agent_dir}/bin/":
    ensure  => 'present',
    mode    => '0755',
    recurse => true,
  }

  augeas { 'buildAgent.properties':
    lens    => 'Properties.lns',
    incl    => "${destination_dir}/${agent_dir}/conf/buildAgent.properties",
    changes => ["set name ${agent_name}", "set serverUrl ${server_url}"],
  }

  # init.d script
  file { '/etc/init.d/build-agent':
    ensure  => 'present',
    owner   => 'root',
    group   => 'root',
    mode    => '0755',
    content => template('teamcity/build-agent.erb'),
  }

  service { 'build-agent':
    ensure     => $service_ensure,
    enable     => $service_enable,
    hasstatus  => true,
    hasrestart => false,
  }

  Wget['teamcity-buildagent'] -> File[$destination_dir] -> Exec['extract-build-agent'] -> File["${destination_dir}/${agent_dir}/bin/"
    ] -> Augeas['buildAgent.properties'] -> File['/etc/init.d/build-agent'] -> Service['build-agent']
}
