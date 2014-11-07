# PRIVATE CLASS: do not call directly
class teamcity::agent::config {
  $agent_name        = $teamcity::agent::agent_name
  $agent_dir         = $teamcity::agent::agent_dir
  $server_url        = $teamcity::agent::server_url
  $custom_properties = $teamcity::agent::custom_properties

  if $::operatingsystem == 'Ubuntu' and $::operatingsystemrelease <= '12.04'{
    file {'/usr/share/augeas/lenses/dist/properties.aug':
      source => "puppet:///modules/${module_name}/properties.aug",
      owner  => 'root',
      group  => 'root',
    }
    File['/usr/share/augeas/lenses/dist/properties.aug'] -> Augeas<||>
  }

  augeas { 'buildAgent.properties':
    lens    => 'Properties.lns',
    incl    => "${agent_dir}/conf/buildAgent.properties",
    changes => [
      "set name ${agent_name}",
      "set serverUrl ${server_url}"
    ],
  }

  augeas { 'buildAgent.properties-custom':
    lens    => 'Properties.lns',
    incl    => "${agent_dir}/conf/buildAgent.properties",
    changes => suffix(
      prefix(
        join_keys_to_values(
          $custom_properties, ' "'
        ), 'set '
      ), '"'
    ),
  }

  augeas { 'wrapper.conf':
    lens    => 'Properties.lns',
    incl    => "${agent_dir}/launcher/conf/wrapper.conf",
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


  file { "/etc/profile.d/teamcity.sh":
    owner   => "root",
    group   => "root",
    mode    => 755,
    content => template("${module_name}/teamcity-profile.erb"),
  }

}
