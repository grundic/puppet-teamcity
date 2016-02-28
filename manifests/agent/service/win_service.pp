# PRIVATE CLASS: do not call directly
# Class for managing Windows service
class teamcity::agent::service::win_service {
  $agent_dir_win = regsubst($::teamcity::agent_dir, '/', '\\', 'G')
  $shortcut_path = "C:\\Users\\${::teamcity::agent_user}\\AppData\\Roaming\\Microsoft\\Windows\\Start Menu\\Programs\\Startup\\TeamCity.lnk"

  exec { 'install-teamcity-agent-service':
    path    => $::path,
    command => "\"${::teamcity::agent_dir}\\launcher\\bin\\TeamCityAgentService-windows-x86-32.exe\" --install ${::teamcity::agent_dir}\\launcher\\conf\\wrapper.conf",
    unless  => 'sc query "TCBuildAgent"',
  }

  service { 'TCBuildAgent':
    ensure  => $::teamcity::service_ensure,
    enable  => $::teamcity::service_enable,
    require => Exec['install-teamcity-agent-service'],
  }

  file { $shortcut_path:
    ensure => absent,
  }
}