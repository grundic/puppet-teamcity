
class teamcity::agent::service {
  service { 'build-agent':
    ensure     => $service_ensure,
    enable     => $service_enable,
    hasstatus  => true,
    hasrestart => false,
  }
}
