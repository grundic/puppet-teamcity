# PRIVATE CLASS: do not call directly
class teamcity::agent::service {
  if $::kernel == 'windows' {
    $agent_dir_win = regsubst($::teamcity::agent_dir, '/', '\\', 'G')
    $shortcut_path = "C:\\Users\\${::teamcity::agent_user}\\AppData\\Roaming\\Microsoft\\Windows\\Start Menu\\Programs\\Startup\\TeamCity.lnk"

    if $::teamcity::service_run_type == 'service' {
      exec { 'install-teamcity-agent-service':
        path    => $::path,
        command => "\"${::teamcity::agent_dir}\\launcher\\bin\\TeamCityAgentService-windows-x86-32.exe\" --install ${::teamcity::agent_dir}\\launcher\\conf\\wrapper.conf",
        unless  => 'sc query "TCBuildAgent"'
      }

      service { 'TCBuildAgent':
        ensure  => $::teamcity::service_ensure,
        enable  => $::teamcity::service_enable,
        require => Exec['install-teamcity-agent-service'],
      }

      file { $shortcut_path:
        ensure => absent
      }
    }
    elsif $::teamcity::service_run_type == 'standalone' {
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
    else {
      fail("'service_run_type' must be either 'service' or 'standalone', but received '${::teamcity::service_run_type}'!")
    }
  }
  else {
    if $::teamcity::service_run_type == 'systemd' {
      service { 'build-agent':
        ensure     => $::teamcity::service_ensure,
        enable     => $::teamcity::service_enable,
        hasstatus  => true,
        hasrestart => true,
        provider   => $::teamcity::service_run_type,
        require    => File['/lib/systemd/system/build-agent.service'],
      }
      exec { 'systemd_reload':
        command     => '/bin/systemctl daemon-reload',
        refreshonly => true,
      }
      file { '/etc/init.d/build-agent':
        ensure  => absent,
      }
    } elsif $::teamcity::service_run_type == 'init' {
      service { 'build-agent':
        ensure     => $::teamcity::service_ensure,
        enable     => $::teamcity::service_enable,
        hasstatus  => true,
        hasrestart => true,
        require    => File['/etc/init.d/build-agent']
      }
      file { '/lib/systemd/system/build-agent.service':
        ensure  => absent,
      }
    }
  }
}
