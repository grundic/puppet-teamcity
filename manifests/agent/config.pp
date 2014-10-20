
class teamcity::agent::config {

  if $::operatingsystem == 'Ubuntu' and $::operatingsystemrelease <= '12.04'{
    file {'/usr/share/augeas/lenses/dist/properties.aug':
      source => "puppet:///modules/${module_name}/properties.aug",
      owner  => 'root',
      group  => 'root',
    }
  }

  augeas { 'buildAgent.properties':
    lens    => 'Properties.lns',
    incl    => "${teamcity::agent_dir}/conf/buildAgent.properties",
    changes => [
      "set name ${teamcity::agent_name}",
      "set serverUrl ${teamcity::server_url}"
    ],
  }

  augeas { 'buildAgent.properties-custom':
    lens    => 'Properties.lns',
    incl    => "${teamcity::agent_dir}/conf/buildAgent.properties",
    changes => suffix(
      prefix(
        join_keys_to_values(
          $teamcity::custom_properties, ' "'
        ), 'set '
      ), '"'
    ),
  }

  augeas { 'wrapper.conf':
    lens    => 'Properties.lns',
    incl    => "${teamcity::agent_dir}/launcher/conf/wrapper.conf",
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
}
