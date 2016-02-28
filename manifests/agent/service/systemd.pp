# PRIVATE CLASS: do not call directly
# Class for managing system.d service
class teamcity::agent::service::systemd {

  file { '/lib/systemd/system/build-agent.service':
    ensure  => 'file',
    owner   => 'root',
    group   => 'root',
    mode    => '0755',
    content => template("${module_name}/build-agent-service.erb"),
    before  => Service['build-agent.service'],
    notify  => Exec['systemd_reload'],
  }

  exec { 'systemd_reload':
    command     => '/bin/systemctl daemon-reload',
    refreshonly => true,
  }

  service { 'build-agent.service':
    ensure     => $::teamcity::service_ensure,
    enable     => $::teamcity::service_enable,
    hasstatus  => true,
    hasrestart => true,
    provider   => 'systemd',
    require    => Exec['systemd_reload'],
  }

  file { '/etc/init.d/build-agent':
    ensure  => absent,
  }
}