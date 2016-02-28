# PRIVATE CLASS: do not call directly
# Class for managing init.d service
class teamcity::agent::service::initd {

  file { '/etc/init.d/build-agent':
    ensure  => 'file',
    owner   => 'root',
    group   => 'root',
    mode    => '0755',
    content => template("${module_name}/build-agent.erb"),
    before  => Service['build-agent'],
    notify  => Service['build-agent'],
  }

  service { 'build-agent':
    ensure     => $::teamcity::service_ensure,
    enable     => $::teamcity::service_enable,
    hasstatus  => true,
    hasrestart => true,
    require    => File['/etc/init.d/build-agent'],
  }

  file { '/lib/systemd/system/build-agent.service':
    ensure  => absent,
  }
}