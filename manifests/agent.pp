
class teamcity::agent (
  $agent_name,
  $agent_user              = $teamcity::params::agent_user,
  $agent_user_home         = $teamcity::params::agent_user_home,
  $manage_agent_user_home  = $teamcity::params::manage_agent_user_home,
  $agent_group             = $teamcity::params::agent_group,
  $manage_user             = $teamcity::params::manage_user,
  $manage_group            = $teamcity::params::manage_group,
  $service_ensure          = $teamcity::params::service_ensure,
  $service_enable          = $teamcity::params::service_enable,
  $server_url              = $teamcity::params::server_url,
  $archive_name            = $teamcity::params::archive_name,
  $download_url            = $teamcity::params::download_url,
  $agent_dir               = $teamcity::params::agent_dir,
  $teamcity_agent_mem_opts = $teamcity::params::teamcity_agent_mem_opts) inherits ::teamcity::params {

  if $::operatingsystem == 'Ubuntu' and $::operatingsystemrelease <= '12.04'{
    file {"/usr/share/augeas/lenses/dist/properties.aug":
      source => "puppet:///modules/${module_name}/properties.aug",
      owner  => 'root',
      group  => 'root',
    }
  }

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
      $agent_user_home_real = $agent_user_home ? {
        undef   => $agent_dir,
        default => $agent_user_home,
      }

      user { $agent_user:
        ensure     => 'present',
        home       => $agent_user_home,
        managehome => $manage_agent_user_home,
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

  exec { "create ${agent_dir}":
    path    => ['/usr/local/bin', '/usr/bin', '/bin'],
    command => "mkdir -p ${agent_dir}",
    creates => $agent_dir,
  }

  exec { 'extract-build-agent':
    path      => ['/usr/local/bin', '/usr/bin', '/bin'],
    command   => "unzip -d ${agent_dir} /tmp/${archive_name} && cp ${agent_dir}/conf/buildAgent.dist.properties ${agent_dir}/conf/buildAgent.properties && chown -R ${agent_user}:${agent_group} ${agent_dir}",
    creates   => "${agent_dir}/conf",
    logoutput => 'on_failure',
  }

  # make 'bin' folder executable
  file { "${agent_dir}/bin/":
    ensure  => 'present',
    mode    => '0755',
    recurse => true,
  }

  augeas { 'buildAgent.properties':
    lens    => 'Properties.lns',
    incl    => "${agent_dir}/conf/buildAgent.properties",
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

  Wget::Fetch['teamcity-buildagent'] -> Exec["create ${agent_dir}"] -> Exec['extract-build-agent'] -> File["${agent_dir}/bin/"] ->
  Augeas['buildAgent.properties'] -> File['/etc/init.d/build-agent'] -> Service['build-agent']
}
