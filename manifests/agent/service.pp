# PRIVATE CLASS: do not call directly
class teamcity::agent::service {
  if is_array($teamcity::params::service_providers) {
    # Verify the service provider given is in the array
    if ! ($teamcity::service_provider in $teamcity::params::service_providers) {
      fail("'${teamcity::service_provider}' is not a valid provider for '${::operatingsystem}'")
    }
    $real_service_provider = $teamcity::service_provider
  } else {
    # There is only one option so simply set it
    $real_service_provider = $teamcity::params::service_providers
  }

  case $real_service_provider {
    'init': {
      $class_name = 'initd'
    }
    'systemd': {
      $class_name = 'systemd'
    }
    'service': {
      $class_name = 'win_service'
    }
    'standalone': {
      $class_name = 'win_service'
    }
    default: {
      fail("Unknown service provider '${real_service_provider}'!")
    }
  }

  anchor { '::teamcity::agent::service::start': } ->
  class{ "::teamcity::agent::service::${class_name}": } ->
  anchor { '::teamcity::agent::service::end': }
}