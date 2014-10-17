package {'unzip':
  ensure => installed
}


class {'::teamcity::agent':
  agent_name        => 'sample-build-agent',
  manage_user       => true,
  manage_group      => true, 
  custom_properties => {
      "system.teamcity.idea.home" => "%system.agent.home.dir%/tools/idea"
  }
}

