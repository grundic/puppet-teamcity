
class teamcity::agent (
  $agent_name,

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

  Exec { path => [ '/bin/', '/sbin/' , '/usr/bin/', '/usr/sbin/', '/usr/local/bin' ] }

  if $::operatingsystem == 'Ubuntu' and $::operatingsystemrelease <= '12.04'{
    file {'/usr/share/augeas/lenses/dist/properties.aug':
      source => "puppet:///modules/${module_name}/properties.aug",
      owner  => 'root',
      group  => 'root',
    }
  }

  if $manage_group {
    if !defined(Group[$agent_group]) {
      group { $agent_group: ensure => 'present', }
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
        home       => $agent_user_home_real,
        managehome => $manage_agent_user_home,
        gid        => $agent_group,
        shell      => '/bin/sh',
        require    => $group_require,
      }
    }
  }

  wget::fetch { 'teamcity-buildagent':
    source      => $download_url,
    destination => "/tmp/${archive_name}",
    timeout     => 0,
  }

  exec { 'extract-agent-archive':
    command   => "unzip /tmp/${archive_name} -d ${agent_dir}",
    creates   => "${agent_dir}/conf",
    logoutput => 'on_failure',
  }

  file {'agent-config':
    path    => "${agent_dir}/conf/buildAgent.properties",
    ensure  => 'present',
    replace => 'no',
    source  => "${agent_dir}/conf/buildAgent.dist.properties",
    group   => $agent_group,
    owner   => $agent_user
  }

  exec { 'chown-agent-dir':
    command     => "chown -R ${agent_user}:${agent_group} ${agent_dir}",
    subscribe   => Exec['extract-agent-archive'],
    refreshonly => true,
    logoutput   => 'on_failure',
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

  augeas { 'buildAgent.properties-custom':
    lens    => 'Properties.lns',
    incl    => "${agent_dir}/conf/buildAgent.properties",
    changes => suffix(prefix(join_keys_to_values($custom_properties, ' "'), 'set '), '"'),
  }

  augeas { 'wrapper.conf':
    lens    => 'Properties.lns',
    incl    => "${destination_dir}/${agent_dir}/launcher/conf/wrapper.conf",
    changes => ['set wrapper.app.parameter.11 -Dfile.encoding=UTF-8'],
  }

  # init.d script
  file { '/etc/init.d/build-agent':
    ensure  => 'present',
    owner   => 'root',
    group   => 'root',
    mode    => '0755',
    content => template("${module_name}/build-agent.erb"),
  }

  service { 'build-agent':
    ensure     => $service_ensure,
    enable     => $service_enable,
    hasstatus  => true,
    hasrestart => false,
  }

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
