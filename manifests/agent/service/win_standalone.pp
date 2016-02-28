# PRIVATE CLASS: do not call directly
# Class for managing agent via Auto Startup
class teamcity::agent::service::win_standalone {
  $agent_dir_win = regsubst($::teamcity::agent_dir, '/', '\\', 'G')
  $shortcut_path = "C:\\Users\\${::teamcity::agent_user}\\AppData\\Roaming\\Microsoft\\Windows\\Start Menu\\Programs\\Startup\\TeamCity.lnk"

  exec { 'create-teamcity-agent-shortcut':
    command   => template("${module_name}/create-shortcut.ps1"),
    creates   => $shortcut_path,
    provider  => 'powershell',
    logoutput => true,
  }

  exec { 'uninstall-teamcity-agent-service':
    path     => $::path,
    command  => "cmd /c '\"${agent_dir_win}\\launcher\\bin\\TeamCityAgentService-windows-x86-32.exe\" --remove ${agent_dir_win}\\launcher\\conf\\wrapper.conf'",
    unless   => template("${module_name}/check-service.ps1"),
    provider => powershell,
  }
}