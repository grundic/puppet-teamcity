# PRIVATE CLASS: do not call directly
class teamcity::agent::service {
  $service_ensure  = $teamcity::agent::service_ensure
  $service_enable  = $teamcity::agent::service_enable

  service { 'build-agent':
    ensure     => $service_ensure,
    enable     => $service_enable,
    hasstatus  => true,
    hasrestart => false,
  }
}
