# PRIVATE CLASS: do not call directly
class teamcity::agent::service {
  $agent_dir         = $teamcity::agent::agent_dir
  $service_ensure    = $teamcity::agent::service_ensure
  $service_enable    = $teamcity::agent::service_enable
  $service_run_type  = $teamcity::agent::service_run_type
  $agent_user        = $teamcity::agent::agent_user

  if $::kernel == 'windows' {
    $agent_dir_win = regsubst($agent_dir, '/', '\\', 'G')
    $shortcut_path = "C:\\Users\\${agent_user}\\AppData\\Roaming\\Microsoft\\Windows\\Start Menu\\Programs\\Startup\\TeamCity.lnk"

    if $service_run_type == 'service' {
      exec { 'install-teamcity-agent-service':
        path    => $::path,
        command => "\"${agent_dir}\\launcher\\bin\\TeamCityAgentService-windows-x86-32.exe\" --install ${agent_dir}\\launcher\\conf\\wrapper.conf",
        unless  => 'sc query "TCBuildAgent"'
      }

      service { 'TCBuildAgent':
        ensure  => $service_ensure,
        enable  => $service_enable,
        require => Exec['install-teamcity-agent-service'],
      }

      file {$shortcut_path:
        ensure => absent
      }
    }
    elsif $service_run_type == 'standalone' {
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
      fail('$service_run_type must be either service or standalone')
    }
  }
  else {
    if $service_run_type == 'systemd' {
      service { 'build-agent':
        ensure     => $service_ensure,
        enable     => $service_enable,
        hasstatus  => true,
        hasrestart => true,
        provider   => $service_run_type,
        require    => File['/lib/systemd/system/build-agent.service'],
      }
      exec { 'systemd_reload':
        command     => '/bin/systemctl daemon-reload',
        refreshonly => true,
      }
      file { '/etc/init.d/build-agent':
        ensure  => absent,
      }
    }elsif $service_run_type == 'init' {
      service { 'build-agent':
        ensure     => $service_ensure,
        enable     => $service_enable,
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
